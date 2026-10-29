using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;

namespace Practica001.Data;

// Requires a valid, unexpired Bearer token. Anything other than GET also requires the Admin role.
[AttributeUsage(AttributeTargets.Class)]
public class TokenAuthAttribute : Attribute, IAsyncAuthorizationFilter
{
    // Authorization filters run before [ApiController]'s automatic 400, so bad bodies can't bypass the 401/403.
    public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        var db = context.HttpContext.RequestServices.GetRequiredService<AppDbContext>();

        var header = context.HttpContext.Request.Headers.Authorization.ToString();
        var valor = header.Replace("Bearer ", "").Trim();

        var token = await db.Tokens.FirstOrDefaultAsync(t => t.Token == valor && t.Activo);

        if (token == null)
        {
            context.Result = new UnauthorizedObjectResult(new { error = "Token inválido" });
            return;
        }

        if (token.FechaExpiracion <= DateTime.Now)
        {
            token.Activo = false;
            await db.SaveChangesAsync();
            context.Result = new UnauthorizedObjectResult(new { error = "Token expirado" });
            return;
        }

        if (!HttpMethods.IsGet(context.HttpContext.Request.Method))
        {
            var rol = await (from u in db.Usuarios
                             join r in db.Roles on u.Rol equals r.Id
                             where u.Id == token.UsuarioId
                             select r.RolNombre).FirstOrDefaultAsync();

            if (rol != "Admin")
            {
                context.Result = new ObjectResult(new { error = "Solo un administrador puede realizar esta acción" })
                {
                    StatusCode = StatusCodes.Status403Forbidden
                };
                return;
            }
        }
    }
}
