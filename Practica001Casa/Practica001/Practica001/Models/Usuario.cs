namespace Practica001.Models;

public class Usuario
{
    public int Id { get; set; }

    public string UsuarioNombre { get; set; } = "";

    public string Password { get; set; } = "";

    public string NombreCompleto { get; set; } = "";

    public int Rol { get; set; }

    public bool Estado { get; set; }
}