ECS App Action
==============
Deploy an ECS Application using Terraform.

Usage
-----

```yaml
  - name: My Project
    uses: aplaceformom/terraform-project-base-action@master
    with:
      project: examples
      owner: MyTeam
      email: myteam@mydomain.org
      remote_state_bucket: apfm-terraform-remotestate
      remote_lock_table: terraform-statelock
      shared_state_key: /shared-infra/remotestate.file
  - name: My Service
    uses: aplaceformom/terraform-ecs-app-action@master
    with:
      public: true
      debug: false
```

Inputs
------

### public
Enable Public IP Allocation
- required: false
- default: false

### command
Specify an alternate command/entrypoint for the Docker container
- required: false

### cpu
ECS CPU Allocation
- required: false
- default: 128

### mem
ECS Memory Allocation
- required: false
- default: 512

### certificate
Automatic SSL Certification Creation
- required: false
- default: true

### certificate_alt_names
List of subjective alternate names to apply to the generated SSL cert
- required: false

### autoscaling
Enable/Disable service autoscaling
- required: false
- default: false

### autoscaling_min
Minimum number of ECS tasks during scale-in
- required: false
- default: 3

### autoscaling_max
Maximum number of ECS tasks during scale-out
- required: false
- default: 3

### target_port
TCP/IP port the container is listening on
- required: false
- default: 80

### target_protocol
TCP/IP protocol the container communications with
- required: false
- default: 'http'

### listener_port
TCP/IP port the loadbalancer should listen on
- required: false
- default: 443

### listener_protocol
TCP/IP protocol the loadbalancer uses for communication
 - required: false
- default: 'https'

### health_check_path
Health check path
- required: false
- default: /

### health_check_timeout
Health check timeout
- reqired: false
- default: 60

### health_check_grace
Grace period in which to ignore the health check during task startup
- reqired: false
- default: 120

### debug
enable debugging
- default: false

Outputs
-------

|       Context         |          Description            |
|-----------------------|---------------------------------|
| service-arn           | ECS Service ARN                 |
| task-arn              | ECS Task ARN                    |
| loadbalancer-arn      | Network Loadbalancer ARN        |
| loadbalancer-endpoint | Network Loadbalancer Endpoint   |
| certificate-arn       | SSL Certificate ARN             |
| certificate-name      | DNS Name on the ACM Certificate |

References
----------

- https://help.github.com/en/actions/building-actions/creating-a-docker-container-action
- https://help.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions
- https://help.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables
