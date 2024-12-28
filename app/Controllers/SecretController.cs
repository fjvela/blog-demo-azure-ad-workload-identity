using Azure.Core;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Microsoft.AspNetCore.Mvc;

namespace WebApp.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class SecretController : ControllerBase
    {
        private readonly ILogger<SecretController> _logger;
        private readonly IConfiguration _config;

        public SecretController(ILogger<SecretController> logger, IConfiguration config)
        {
            _logger = logger;
            _config = config;
        }

        [HttpGet(Name = "GetSecret")]
        public IActionResult Get(string name, string credentialType = "DefaultAzureCredential")
        {
            var kvName = _config["KV_NAME"];
            _logger.LogInformation($"C# HTTP trigger function processed a request. {name} {credentialType} {kvName}");

            var tokenCredential = GetTokenCredential(credentialType);
            var client = new SecretClient(new Uri($"https://{kvName}.vault.azure.net/"), tokenCredential);

            return new OkObjectResult(client.GetSecret(name));
        }

        private TokenCredential GetTokenCredential(string credentialType)
        {
            switch (credentialType)
            {
                case "DefaultAzureCredential":
                    return new DefaultAzureCredential();
                case "ChainedTokenCredential":
                    return new ChainedTokenCredential();
                case "ManagedIdentityCredential":
                    return new ManagedIdentityCredential();
            }

            throw new Exception($"The credential type {credentialType} is not valid");
        }
    }
}
