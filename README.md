**Warning** CircleCI has a new [Container runner](https://circleci.com/docs/container-runner) in open preview.  Container runner is the supported method  for using self-hosted runners with Kubernetes.  This documentation is meant for existing users who have not yet migrated to using the container runner.

# Introduction
This guide is a reference for setting up self-hosted runners that use [launch-agent](https://circleci.com/docs/runner-concepts#launch-agent-and-task-agent) on your Kubernetes cluster. **This is the *deprecated* way of using self-hosted runners with Kubernetes.**  The reference guide is being kept here for users still using this deprecated method.  Users looking to use self-hosted runners with Kubernetes should be using the **[container runner] (https://circleci.com/docs/container-runner) for current documentation**.  

This Helm chart will spin up one or more pods of *the same self-hosted runner resource class*. Each runner will pull jobs off the queue on an as-available basis.

If you want to have different self-hosted runners specialized for different workloads, use the [container runner](https://circleci.com/docs/container-runner) to have multiple resource classes associated with the same container runner.

If you are using **Server**, please make sure you read [CircleCI server installation](#circleci-server-installation).

## Prerequisites
- Have a Kubernetes cluster up and running where you'd like to deploy your self-hosted runner(s).
- [Generate a token and resource class](https://circleci.com/docs/runner-installation). For each different type of self-hosted runner you want to run, you will need to repeat these same steps.
  - For example, if you want ten runners that pull the same types of jobs or run the same [parallel job](https://circleci.com/docs/parallelism-faster-jobs/) based on availability, you only need to create one runner resource class. All ten runners would share the same token.

## Setup
1. Clone this repository.
2. Modify values as needed in `values.yaml`:

    Value             | Description                  | Default    | Required
    ------------------|------------------------------|------------|--------------
    image.repository<br />image.tag | You can [extend a custom Docker image](https://circleci.com/docs/runner-installation-docker/#create-a-dockerfile-that-extends-the-circleci-self-hosted-runner-image) from the CircleCI default runner and use that instead.<br />For CircleCI server installations, see the compatible version tags [here](https://circleci.com/docs/runner-installation-cli/#self-hosted-runners-for-server-compatibility). | `circleci/runner`<br />`launch-agent` | Y
    replicaCount      | The number of replicas of this runner you want in your cluster. Must currently be set and updated manually. See [limitations](#limitations). | 1 | Y
    resourceClass     | The resource class you created for your runner. We recommend not inserting it into `values.yaml` directly and setting it when you install your chart instead. See next step. | " " | Y
    runnerToken       | The token you created for your runner. We recommend not inserting it into `values.yaml` directly and setting it when you install your chart instead. See next step. | " " | Y
    All other values  | Modify at your own discretion and risk. | N/A | N/A
    {: class="table table-striped"}

3. Using the resource class name and token you created in the [Prerequisites](#prerequisites) section, you'll want to set parameters as you install the Helm chart:
    ```bash
    $ helm install "circleci-runner" ./ \
      --set runnerToken=$CIRCLECI_RUNNER_TOKEN \
      --set resourceClass=$CIRCLECI_RUNNER_RESOURCE_CLASS \
      --namespace your-namespace
    ```
4. Call your runner class(es) in your job(s). Example:

    ```yaml
    version: 2.1
    executors:
      my-runner:
        machine: true
        resource_class: my-namespace/my-runner-resource-class
      
    workflows:
      my-workflow:
        jobs:
          - my-job
    jobs:
      my-job:
        executor: my-runner
        steps:
          - checkout
          - run: echo "Hello from my custom runner!"
    ```

### Set Environment Variables
Environment variables can be configured in `env` section of the `values.yaml` file. Environment variables can be used to further configure CircleCI's self-hosted runner using the environment variables described on the [Runner configuration reference page](https://circleci.com/docs/runner-config-reference/).
It's also possible to add additional Kubernetes secret references (see example in `env` section of `values.yaml`).

### Setup with Optional Secret Creation
There may be cases where you do not want Helm to create the Secret resource for you. One case would be if you were using a GitOps deployment tool such as ArgoCD or Flux. In these cases you would need to create a secret manually in the same namespace and cluster where the Helm managed runner resources will be deployed.
1. Create the secret:
```bash
$ kubectl create secret generic config-values \
  --namespace your-namespace \
  --from-literal resourceClass=$CIRCLECI_RUNNER_RESOURCE_CLASS \
  --from-literal runnerToken=$CIRCLECI_RUNNER_TOKEN
```
2. Install the Helm chart:
```bash
$ helm install "circleci-runner" ./ \
  --set configSecret.create=false \
  --namespace your-namespace
```

### Setup with parameterized Service Account 
There may be cases where a service account does not need to be created, or one already exists that should be reused. The `values.yaml` file can be modified to accommodate this scenario.

A new service account is created by default with the suggested values.yaml file. Setting the account name to `circleci-runner`. The `serviceAccount.name` value in `values.yaml` can be modified to a different name as required for deployment.

An existing service account can be reused by setting the `serviceAccount.name` parameter in the `values.yaml` file to the name of the existing account, and setting `serviceAccount.create` to `false`. This may be required when creating multiple helm releases from this chart.

More details about using and configuring a service account can be found in the [Helm documentation](https://helm.sh/docs/chart_best_practices/rbac/#yaml-configuration).

## Support Scope
Customers who modify the chart beyond values in `values.yaml` do so at their own risk. The type of support CircleCI provides for those customizations will be limited.   [Container runner](https://circleci.com/docs/container-runner) is the recommended method for using self-hosted runners with Kubernetes.

## Limitations
- Autoscaling is not supported. [Container runner](https://circleci.com/docs/container-runner) supports autoscaling.
- Containers are not privileged, so you cannot execute privileged workloads (e.g., Docker in Docker).

# CircleCI Server Installation

When installing the Helm chart for use with a CircleCI server installation, the `image.tag` will need to be set to the pinned launch agent version specified in the [Self-hosted runner installation](https://circleci.com/docs/runner-installation-cli#self-hosted-runners-for-server-compatibility) instructions. The `LAUNCH_AGENT_API_URL` will also need to be set as an environment variable. This can be done with the `--set` flag, or in the `env` section of the `values.yaml` file, specifying the hostname or address of the server installation.

# Upgrading Self-hosted Runner Deployment for Server

1. Modify the `values.yaml` file to specify the new `image.tag` to update to. Refer to the [setup](#setup) section of this document for more details about the `values.yaml` file.

2. Deploy the changes to the cluster:
```shell
$ helm upgrade -f values.yaml "circleci-runner" ./ \
  --set runnerToken=$CIRCLECI_RUNNER_TOKEN \
  --set resourceClass=$CIRCLECI_RUNNER_RESOURCE_CLASS \
  --set env.LAUNCH_AGENT_API_URL=<server_host> \
  --namespace your-namespace
```

Further information about the `$ helm upgrade` command and its usage can be found in the [Helm documentation](https://helm.sh/docs/helm/helm_upgrade/).
