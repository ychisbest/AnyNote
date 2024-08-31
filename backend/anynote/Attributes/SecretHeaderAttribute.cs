using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Mvc;

namespace anynote.Attributes
{
    public class SecretHeaderAttribute : Attribute, IAuthorizationFilter
    {

        public SecretHeaderAttribute()
        {
            
        }

        public void OnAuthorization(AuthorizationFilterContext context)
        {
            if (string.IsNullOrEmpty(Secret.value))
            {
                return;
            }


            if (!context.HttpContext.Request.Headers.TryGetValue("x-secret", out var secretHeader) || secretHeader != Secret.value)
            {
                context.Result = new UnauthorizedResult();
            }
        }
    }
}
