# With this example configuration
# Test Harness Repository
# GIT URL: https://github.com/Jooho/test-operator-test-harness
# Image URL: quay.io/jooholee/test-operator-test-harness:latest
#
# Manifests
# GIT URL: https://github.com/Jooho/test-operator-manifests
# Image URL: quay.io/jooholee/test-operator-manifests:latest


# OPERATOR_NAME:  # Format %PRODUCT_NAME%-operator ex) odh-operator

PRODUCT_NAME=starburst
OPERATOR_NAME=${PRODUCT_NAME}-operator
OPERATOR_CRD_API=starbursthives.charts.starburstdata.com
GIT_REPO_HOST=https://github.com
GIT_REPO_ORG=Jooho
GIT_REPO_BRANCH=master
IMG_REG_HOST=quay.io
IMG_REG_ORG=jooholee
TEST_NAMESPACE=${OPERATOR_NAME}
TEST_HARNESS_IMG_TAG=latest
MANIFESTS_IMG_TAG=latest
TEST_HARNESS_NAME=${OPERATOR_NAME}-test-harness
MANIFESTS_NAME=${OPERATOR_NAME}-manifests
# JUPYTERHUB_NAMESPACE=redhat-ods-applications
JUPYTERHUB_NAMESPACE=redhat-ods-applications

# JupyterNotebook - Manifests 
# OPENSHIFT_USER/PASS/LOGIN_PROVIDER=admin/admin/test-htpasswd-provider
OPENSHIFT_USER=                  
OPENSHIFT_PASS=                  
OPENSHIFT_LOGIN_PROVIDER=        
TESTS_REGEX=

# Jupyter Notebook
# JUPYTER_NOTEBOOK_PATH should be like "${MANIFESTS_NAME}/notebooks"
# default value: manifests-test/notebooks/tensorflow
# JUPYTER_NOTEBOOK_FILE should be like "XXXX.ipynb"
# default value: TensorFlow-MNIST-Minimal.ipynb
JUPYTER_NOTEBOOK_PATH=abc
JUPYTER_NOTEBOOK_FILE=


#---------------------------------------------
# Do NOT CHANGE
# TEST HARNESS
# TEST_HARNESS_NAME=operator-test-harness

TEST_HARNESS_IMG=${TEST_HARNESS_NAME}
TEST_HARNESS_GIT_REPO_URL=${GIT_REPO_HOST}/${GIT_REPO_ORG}/${TEST_HARNESS_NAME}
TEST_HARNESS_FULL_IMG_URL=${IMG_REG_HOST}/${IMG_REG_ORG}/${TEST_HARNESS_IMG}:${TEST_HARNESS_IMG_TAG}

# MANIFESTS
# MANIFESTS_NAME=manifests-test
MANIFESTS_IMG=${MANIFESTS_NAME}
MANIFESTS_GIT_REPO_URL=${GIT_REPO_HOST}/${GIT_REPO_ORG}/${MANIFESTS_NAME}
MANIFESTS_FULL_IMG_URL=${IMG_REG_HOST}/${IMG_REG_ORG}/${MANIFESTS_IMG}:${MANIFESTS_IMG_TAG}
## Location inside the container where CI system will retrieve files after a test run
ARTIFACT_DIR=/tmp/artifacts
LOCAL_ARTIFACT_DIR="${PWD}/artifacts"

