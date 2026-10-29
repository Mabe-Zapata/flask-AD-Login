
using Practica001.Models.Dto;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Practica001.Data;
using Practica001.Models;
using System.Security.Cryptography;

namespace Practica001.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;

    private readonly int _minutosToken;

    public AuthController(AppDbContext context, IConfiguration config)
    {
        _context = context;
        _minutosToken = config.GetValue("Token:Minutos", 5);
    }

    [HttpGet("validar")]
    public async Task<IActionResult> Validar([FromHeader(Name = "Authorization")] string? authorization)
    {
        var valor = authorization?.Replace("Bearer ", "").Trim();

        var token = await _context.Tokens
            .FirstOrDefaultAsync(t => t.Token == valor && t.Activo);

        if (token == null)
            return Unauthorized(new { error = "Token inválido" });

        if (token.FechaExpiracion <= DateTime.Now)
        {
            token.Activo = false;
            await _context.SaveChangesAsync();
            return Unauthorized(new { error = "Token expirado" });
        }

        return Ok(new { mensaje = "Token válido", expiracion = token.FechaExpiracion });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest request)
    {
        var usuario = await _context.Usuarios
            .FirstOrDefaultAsync(u =>
                u.UsuarioNombre == request.Usuario &&
                u.Password == request.Password &&
                u.Estado == true);

        if (usuario == null)
        {
            return Unauthorized(new
            {
                error = "Usuario o contraseña incorrectos"
            });
        }

        var rol = await _context.Roles
            .Where(r => r.Id == usuario.Rol)
            .Select(r => r.RolNombre)
            .FirstOrDefaultAsync();

        if (rol == null)
        {
            return Unauthorized(new
            {
                error = "El usuario no tiene un rol válido"
            });
        }

        string tokenGenerado = Convert.ToHexString(
            RandomNumberGenerator.GetBytes(32));

        var token = new TokenUsuario
        {
            UsuarioId = usuario.Id,
            Token = tokenGenerado,
            FechaCreacion = DateTime.Now,
            FechaExpiracion = DateTime.Now.AddMinutes(_minutosToken),
            Activo = true
        };

        _context.Tokens.Add(token);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            mensaje = "Login correcto",
            usuario = new
            {
                usuario.Id,
                usuario.UsuarioNombre,
                usuario.NombreCompleto,
                Rol = rol
            },
            token = tokenGenerado,
            expiracion = token.FechaExpiracion
        });
    }
}
