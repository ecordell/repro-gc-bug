function randomapi {
    kind=$(echo "api$RANDOM")
    group=$(echo "$RANDOM.group.com")
    cat <<EOF | kubectl replace --force -f -
apiVersion: apiregistration.k8s.io/v1beta1
kind: APIService
metadata:
  name: v1.$group
spec:
  insecureSkipTLSVerify: true
  group: $group
  groupPriorityMinimum: 1000
  versionPriority: 15
  service:
    name: apiserver-$kind
    namespace: default
  version: v1
---
apiVersion: v1
kind: Service
metadata:
  name: apiserver-$kind
  namespace: default
spec:
  ports:
  - port: 443
    protocol: TCP
    targetPort: 5443
  selector:
    app: mock-apiserver-$kind
---
kind: ServiceAccount
apiVersion: v1
metadata:
  name: apiserver-$kind
  namespace: default
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: aggregated-apiserver-clusterrole
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $kind-apiserver-clusterrolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: aggregated-apiserver-clusterrole
subjects:
- kind: ServiceAccount
  name: apiserver-$kind
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $kind:system:auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: apiserver-$kind
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $kind-auth-reader
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: extension-apiserver-authentication-reader
subjects:
- kind: ServiceAccount
  name: apiserver-$kind
  namespace: default
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mock-apiserver-$kind
  labels:
    app: mock-apiserver-$kind
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mock-apiserver-$kind
  template:
    metadata:
      labels:
        app: mock-apiserver-$kind
    spec:
      serviceAccountName: apiserver-$kind
      containers:
      - name: apiserver-$kind
        image: quay.io/coreos/mock-extension-apiserver:master
        command: 
        - /bin/mock-extension-apiserver
        args:
        - -v=4
        - --mock-kinds
        - $kind
        - --mock-group-version
        - $group/v1
        - --secure-port
        - '5443'
        ports:
        - containerPort: 5443
EOF
}

function randomCRD {
    crd=$(echo "crd$RANDOM")
    group=$(echo "$RANDOM.group.com")
    cat <<EOF | kubectl replace --force -f -
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: $crd.$group
spec:
  group: $group
  versions:
    - name: v1
      served: true
      storage: false
    - name: v2
      served: true
      storage: true
  scope: Namespaced
  names:
    plural: $crd
    singular: $crd
    kind: $crd
EOF
    cat <<EOF | kubectl replace --force -f -
apiVersion: "$group/v1"
kind: $crd
metadata:
  name: example
  namespace: default
EOF
}

function genCRDs {
    count=$1
    until [[ $count == 0 ]]; do
        randomCRD
        count=$((count - 1))
    done
}
 
function genAPIs {
    count=$1
    until [[ $count == 0 ]]; do
        randomapi
        count=$((count - 1))
    done
}
