DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
OUT_FILE := "$(DIR)$(TEST_HARNESS_NAME)"

include $(shell pwd)/env
build:
	CGO_ENABLED=0 go test -v -c

build-image:
	@echo "Building the $(TEST_HARNESS_NAME)"
	podman build --format docker -t $(TEST_HARNESS_FULL_IMG_URL) -f $(shell pwd)/Dockerfile .

push-image:
	@echo "Pushing the $(TEST_HARNESS_NAME) image to $(IMG_REG_HOST)/$(IMG_REG_ORG)"
	podman push $(TEST_HARNESS_FULL_IMG_URL)

image: build-image push-image

final-image:
	$(eval old_ns := $(shell cat env.sh|grep JUPYTERHUB_NAMESPACE|cut -d '=' -f2))
	sed 's/JUPYTERHUB_NAMESPACE=.*/JUPYTERHUB_NAMESPACE=redhat-ods-applications/g' -i env.sh
	make image	
	sed "s/JUPYTERHUB_NAMESPACE=.*/JUPYTERHUB_NAMESPACE=$(old_ns)/g" -i env.sh

# This script create a SA which has cluster-admin role. This is needed to mimik OSD E2E test environment.
test-setup:
	./hack/setup.sh

# If your cluster does not have RHODS ADDON, you can test your test-harness with ODH.
# This will deploy ODH in opendatahub namespace 
odh-deploy:
	oc project $(JUPYTERHUB_NAMESPACE) || oc new-project $(JUPYTERHUB_NAMESPACE)
	oc get subs opendatahub-operator -n openshift-operators || oc create -f ./hack/odh-operator/subs.yaml
	$(eval kfdef_installed := $(shell oc api-versions|grep kfdef|wc -l)) 
	sleep 10
	oc create -f ./hack/odh-operator/cr.yaml -n $(JUPYTERHUB_NAMESPACE)

# This will delete ODH objects	
odh-clean:
	oc project $(JUPYTERHUB_NAMESPACE)
	$(eval kfdef_exist := $(shell oc get kfdef/opendatahub -n $(JUPYTERHUB_NAMESPACE) --ignore-not-found|wc -l)) 
ifeq ($(kfdef_exist),"1")
	oc delete -f ./hack/odh-operator/cr.yaml -n $(JUPYTERHUB_NAMESPACE) --force --grace-period=0 --wait=false
	oc patch kfdef/opendatahub -n $(JUPYTERHUB_NAMESPACE) --type json -p '[{"op": "remove", "path": "/metadata/finalizers"}]'
endif
	oc delete all --all -n $(JUPYTERHUB_NAMESPACE) --force --grace-period=0
	oc delete -f ./hack/odh-operator/subs.yaml --wait
	oc delete project $(JUPYTERHUB_NAMESPACE) --force --grace-period=0
	oc delete -n openshift-operators csv $$(oc get csv -n openshift-operators|grep opendatahub|cut -d" " -f1)

# It deploys custom ISV operator using custom index.
# It gives you more flexible test environment and you can even test un-published new operator version.
isv-operator-deploy:
	oc project $(TEST_NAMESPACE) || oc new-project $(TEST_NAMESPACE)
	oc get subs starburst-enterprise-helm-operator-certified-rhmp -n openshift-operators ||oc create -f ./hack/$(OPERATOR_NAME)/subs.yaml
	sleep 10
	oc create -f ./hack/$(OPERATOR_NAME)/cr.yaml -n $(TEST_NAMESPACE) 

# It removes ISV operator with oc commands.
isv-operator-clean:
	oc project $(TEST_NAMESPACE)
	oc delete -f ./hack/$(OPERATOR_NAME)/cr.yaml -n $(TEST_NAMESPACE)  --ignore-not-found
	oc delete -f ./hack/$(OPERATOR_NAME)/subs.yaml  --ignore-not-found
	oc delete csv -n openshift-operators $$(oc get csv |grep $(PRODUCT_NAME)|cut -d" " -f1)
	
# Test harness image will create a job object to deploy manifest but you can test only the job object. Before you test the test harness image on the cluster, this job must work.
job-test:
	oc delete job $(MANIFESTS_NAME)-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc get sa $(MANIFESTS_NAME)-sa -n $(TEST_NAMESPACE) || $(MAKE) test-setup
	./hack/manifests-job.sh create
	

job-test-clean:
	oc delete sa $(MANIFESTS_NAME)-sa -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete rolebinding $(MANIFESTS_NAME)-rb -n $(TEST_NAMESPACE) --ignore-not-found
	./hack/manifests-job.sh  delete
	oc delete pod -l job_name=$(MANIFESTS_NAME)-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod jupyterhub-nb-admin -n $(JUPYTERHUB_NAMESPACE)  --ignore-not-found --force --grace-period=0
	oc delete pod jupyterhub-nb-admin -n rhods-notebooks  --ignore-not-found --force --grace-period=0
	oc delete pvc jupyterhub-nb-admin-pvc -n $(JUPYTERHUB_NAMESPACE)  --ignore-not-found
	oc delete pvc jupyterhub-nb-admin-pvc -n rhods-notebooks  --ignore-not-found

# After job-test succeed, testing it on the cluster is the last step before you push the test harness image.
cluster-test:
	oc delete pod $(TEST_HARNESS_NAME)-pod -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete job manifests-test-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod -l job_name=$(MANIFESTS_NAME)-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc get sa $(MANIFESTS_NAME)-sa -n $(TEST_NAMESPACE) || $(MAKE) test-setup
	./hack/operator-test-harness-pod.sh create

  # For reference, it can run test harness pod by oc cli
	# oc run $(TEST_HARNESS_NAME)-pod --image=$(TEST_HARNESS_FULL_IMG_URL) --restart=Never --attach -i --tty --serviceaccount $(TEST_HARNESS_NAME)-sa -n $(TEST_NAMESPACE) --env=JOB_PATH=/home/prow-manifest-test-job-pvc.yaml
	# Check logs
	# oc logs $(TEST_HARNESS_NAME)-pod -f -c operator

# Clean all related objects for cluster test
cluster-test-clean:
	./hack/operator-test-harness-pod.sh delete
	oc delete -f ./template/manifests-test-job.yaml -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete -f ./template/download-artifacts-pod.yaml --ignore-not-found
	oc delete -f ./template/artifacts-pvc.yaml --ignore-not-found
	oc delete sa $(MANIFESTS_NAME)-sa -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete rolebinding $(MANIFESTS_NAME)-rb -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod -l job_name=$(MANIFESTS_NAME)-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod jupyterhub-nb-admin  -n redhat-ods-applications --ignore-not-found --force --grace-period=0
	oc delete pvc jupyterhub-nb-admin-pvc -n redhat-ods-applications  --ignore-not-found
