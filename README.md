# hello-ecs-blue-green-deployment

Warning: not yet working

<https://aws.amazon.com/blogs/aws/accelerate-safe-software-releases-with-new-built-in-blue-green-deployments-in-amazon-ecs/>

## Notes
- No UI button "Green looks good, proceed" 
  - instead all API driven with lambda lifecycle hooks
    - could set up custom trigger via SSM Parameter or S3 object - TODO

## Observations

- bake time 0
- Initial state

```
curl http://hello-ecs-blue-green-whoami-56199301.us-east-1.elb.amazonaws.com
Name: Standard Deployment
```

- Update service task definition - results in two tasks running

```
curl http://hello-ecs-blue-green-whoami-56199301.us-east-1.elb.amazonaws.com
Name: Standard Deployment

...

curl -H 'X-Blue-Green: Test' http://hello-ecs-blue-green-whoami-56199301.us-east-1.elb.amazonaws.com
Name: New Deployment
```

- couple minutes later, both curls go to same "New Deployment" with 1 task running
    - Both Listener Rules modified so they have 100% traffic goign to "green" (new)