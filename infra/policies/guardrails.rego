package infra.guardrails

import input as tfplan

# -------------------------------------------------------------------------
# Tagging Enforcement Guardrail
# -------------------------------------------------------------------------
# Ensures all AWS resources that support tags have the mandatory tags.
mandatory_tags = {"Environment", "Project", "Owner"}

deny[msg] {
    # Find all resource creations or modifications in the TF plan
    resource := tfplan.resource_changes[_]
    resource.change.actions[_] == "create"
    
    # Exclude resources that don't support tagging (simplified for example)
    not ignore_resource(resource.type)
    
    # Extract tags
    tags := resource.change.after.tags
    
    # Check if any mandatory tag is missing
    missing_tags := mandatory_tags - set([key | tags[key]])
    count(missing_tags) > 0
    
    msg := sprintf(
        "Resource '%v' is missing mandatory tags: %v. All infrastructure must be properly tagged for cost attribution and governance.",
        [resource.address, missing_tags]
    )
}

# -------------------------------------------------------------------------
# Security Group Best Practice Guardrail
# -------------------------------------------------------------------------
# Prevents creating security groups that allow 0.0.0.0/0 on port 22 (SSH)
deny[msg] {
    resource := tfplan.resource_changes[_]
    resource.type == "aws_security_group"
    resource.change.actions[_] == "create"
    
    ingress := resource.change.after.ingress[_]
    
    # Check if it allows SSH from anywhere
    ingress.from_port <= 22
    ingress.to_port >= 22
    ingress.cidr_blocks[_] == "0.0.0.0/0"
    
    msg := sprintf(
        "Security Group '%v' allows SSH (port 22) from '0.0.0.0/0'. This violates SOC 2 Security principles. Access must be restricted to internal networks or VPN IPs only.",
        [resource.address]
    )
}

# -------------------------------------------------------------------------
# Helper functions
# -------------------------------------------------------------------------
ignore_resource(type) {
    # List of resources that do not inherently support standard AWS tags
    unsupported_types = {"aws_route53_record", "aws_iam_role_policy_attachment"}
    unsupported_types[type]
}
