# Azure AD Workload Identity

Código fuente post: https://blog.javivela.dev/p/azure-ad-workload-identity

## Pipeline

[.github/workflows/main.yaml](.github/workflows/main.yaml) se ejecuta en cada push a `main`:

1. **infra**: despliega `infra/azure` con OpenTofu.
2. **build**: construye la imagen de `app` y la sube al Azure Container Registry.
3. **deploy**: despliega `infra/k8s/app.yaml` en AKS.

El pipeline se autentica en Azure con una federated identity credential, sin secretos ([post](https://blog.javivela.dev/p/azure-federated-identity-credentials)).

[.github/workflows/destroy.yaml](.github/workflows/destroy.yaml) elimina todo lo desplegado por el pipeline. Se lanza manualmente escribiendo `destroy` como confirmación. `infra/bootstrap` se elimina desde local con `tofu destroy`.

### Bootstrap

`infra/bootstrap` se aplica una única vez desde local y crea:

- La managed identity del pipeline y su federated identity credential para la rama `main`.
- El storage account del estado de `infra/azure`.
- Los secrets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` y la variable `TF_STATE_STORAGE_ACCOUNT_NAME` del repositorio.

```bash
cd infra/bootstrap
tofu init
tofu apply -var="azure_subscription_id=<subscription id>" -var="github_token=<token>"
```

El token de GitHub necesita permisos de lectura y escritura sobre *Secrets* y *Variables* del repositorio.

Para inicializar `infra/azure` desde local (por ejemplo, para migrar un estado local con `-migrate-state`):

```bash
cd infra/azure
tofu init -backend-config="storage_account_name=$(tofu -chdir=../bootstrap output -raw tf_state_storage_account_name)"
```
