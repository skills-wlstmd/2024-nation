mkdir -p manifest
mkdir -p manifest/logging
mkdir -p manifest/secret
mkdir -p manifest/networkpolicy
mkdir -p manifest/customer
mkdir -p manifest/product
mkdir -p manifest/order
touch fargate-ns.yaml
touch ingress.yaml
touch manifest/secret/secretstore.yaml
touch manifest/secret/customer.yaml
touch manifest/secret/product.yaml
touch manifest/secret/order.yaml
touch manifest/logging/ns.yaml
touch manifest/logging/customer.yaml
touch manifest/logging/product.yaml
touch manifest/logging/order.yaml
touch manifest/logging/fluentd.yaml
touch manifest/logging/service.yaml
touch manifest/networkpolicy/customer.yaml
touch manifest/networkpolicy/product.yaml
touch manifest/customer/deployment.yaml
touch manifest/customer/service.yaml
touch manifest/product/deployment.yaml
touch manifest/product/service.yaml
touch manifest/order/deployment.yaml
touch manifest/order/service.yaml
