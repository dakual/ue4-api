locals {
    workspace_path = "${path.module}/config.yml" 
    workspace = fileexists(local.workspace_path) ? file(local.workspace_path) : yamlencode({})
    var = merge(
      yamldecode(local.workspace)
    )
}
