# policy.rego
package kubernetes.validation

# By default, deny the request.
default allow = false

# Allow the request only if the input is a Deployment
# and it has an "app" label.
allow = true if {
    input.kind == "Deployment"
    input.metadata.labels.app
}
