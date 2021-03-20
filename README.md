# CircleCI Runner Setup

Repository with various files to install CircleCI's runner on Kubernetes via Helm chart.

## Prerequisites
- You must be on our [Scale Plan](https://circleci.com/pricing/) or sign up for a trial. [Reach out to our sales team](https://circleci.com/contact-us/?cloud) to ask about both.
- [Generate a token and resource class](https://circleci.com/docs/2.0/runner-installation/?section=executors-and-images#authentication) for your runner. For each different type of runner you want to run, you will need to repeat these same steps.
  - For example, if you want ten runners that pull the same jobs based on availability, you only need to run this step once.
  - If you want to run ten separate runners that pull different jobs for different purposes, we recommend creating ten different runner resource classes.
- Have a Kubernetes cluster you would like to install the runner(s) in.

## Setup
1. Clone this repository.
2. Modify values as needed in `values.yaml`:

Value             | Description                  | Default
------------------|------------------------------|-------------
image.repository, image.tag | You can extend a custom Docker image from  the CircleCI default runner and use that instead. | circleci/runner, launch-agent
resource_class    | The resource class you created for your runner. We recommend not inserting it into `values.yaml` directly and setting it when you install your chart instead. See next step. | ""
runner_token      | The token you created for your runner. We recommend not inserting it into `values.yaml` directly and setting it when you install your chart instead. See next step. | ""
All other values  | Modify at your own discretion and risk. | N/A

3. Using the resource class name and token you created in the [Prerequisites](#prerequisites) section, you'll want to set parameters as you install the Helm chart:

```bash
$ helm install "circleci-runner" ./ \
  --set runner_token=$CIRCLECI_RUNNER_TOKEN \
  --set resource_class=$CIRCLECI_RUNNER_RESOURCE_CLASS \
  --namespace your-namespace
```

## Known Issues/Pending Work
- Autoscaling is not yet implemented - for now, you'll need to manually modify the `replicaCount` in `values.yaml`.

