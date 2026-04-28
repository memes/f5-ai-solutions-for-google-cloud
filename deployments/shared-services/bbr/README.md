# Body based routing (Inference Extension for GKE Gateway)

Provides a [Kpt] package for deploying Body Based Routing extension for Inference Gateway.

## Quick steps

1. Fetch package to local directory `bbr`

   <!-- markdownlint-disable line-length -->
   ```shell
   kpt pkg get --for-deployment https://github.com/memes/google-demo-helper-modules.git/packages/gateway-api-inference-extension/body-based-routing bbr
   ```
   <!-- markdownlint-enable line-length -->

1. Edit configuration

   Examine the source files and make changes where necessary. See [Configuration](#configuration) for full details.

1. Deploy the package

   Choose the deployment method that is best suited to your environment.

   1. Deploy with [Skaffold] as Kpt manifest

      To use with [Skaffold] directly or with Cloud Deploy, add a path entry to the package directory under
      `manifests.kpt`.

      E.g.

      ```yaml
      ---
      apiVersion: skaffold/v4beta13
      kind: Config
      metadata:
        name: bbr
        annotations:
          config.kubernetes.io/local-config: "true"
      build: {}
      manifests:
        kpt:
          - path/to/bbr
      deploy:
        kubectl: {}
      ```

      See the [Skaffold] documentation for other examples, including deploying with Kpt.

   1. Render to YAML manifests

      Generating plain YAML from the Kpt package allows the use of any deployment tool that can work with Kubernetes
      manifests. The manifests can be written to a separate location, preserving the Kpt package sources for further
      iteration as needed.

      ```shell
      kpt fn render bbr -o path/to/contain/generated/manifests
      ```

      Remove the `-o` option to replace the Kpt package in-situ with rendered YAML.
      > NOTE: This removes the Kpt package files by default, leaving just the rendered YAML.

      ```shell
      kpt fn render bbr
      ```

   1. Deploy with [kpt]

      See the [kpt book](https://kpt.dev/book/06-deploying-packages/) for more info on deploying with [kpt].

      ```shell
      kpt live init bbr
      kpt live apply bbr
      ```

## Configuration

1. Edit base settings

   1. Set simple parameter values and apply

      Edit [apply-setters.yaml] and update the values to suit your deployment; this file drives most of the
      customization needs of the package and ensures that environment specific settings are applied to the package.

      Performing a manual apply is the *safest* way to ensure the values declared in [apply-setters.yaml] are updated on
      all resources, including Kpt pipeline definitions, before trying to render or deploy the package.

      ```shell
      (cd bbr && \
          kpt fn eval --image ghcr.io/kptdev/krm-functions-catalog/apply-setters:latest --fn-config ./apply-setters.yaml)
      ```

      > NOTE: Ideally, this step is repeated every time values in [apply-setters.yaml] changes. The declared `kpt`
      > pipeline does include this step, but since the files that drive the pipeline are sourced before it is executed
      > the pipeline cannot update itself prior to rendering.

   1. Multi-namespace by default

      The default deployment installs Body Based Routing extension configured to watch for appropriate ConfigMap changes
      in any namespace. If you want to BBR to function watch for changes only in the namespace to which it was deployed
      perform these two steps:

      1. Edit [deploy.yaml] and uncomment the `env` entry that sets NAMESPACE variable from deployed namespace.

      1. Edit [rbac.yaml] and change `ClusterRole` and `ClusterRoleBinding` to `Role` and `RoleBinding`, respectively,
      in the appropriate namespace.

1. Review [Kptfile] and add other local pipeline mutators

   Other mutators should be appended to the end of the existing `pipeline` declaration, if needed.
   See [Kpt function catalog](https://catalog.kpt.dev/) for details.

[kpt]: https://kpt.dev
[skaffold]: https://skaffold.dev
[apply-setters.yaml]: ./apply-setters.yaml
[deploy.yaml]: ./deploy.yaml
[rbac.yaml]: ./rbac.yaml
