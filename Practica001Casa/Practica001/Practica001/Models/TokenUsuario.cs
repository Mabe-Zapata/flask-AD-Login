namespace Practica001.Models;

public class TokenUsuario
{
    public int Id { get; set; }

    public int UsuarioId { get; set; }

    public string Token { get; set; } = "";

    public DateTime FechaCreacion { get; set; }

    public DateTime FechaExpiracion { get; set; }

    public bool Activo { get; set; }
}