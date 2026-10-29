
using Microsoft.EntityFrameworkCore;
using Practica001.Models;

namespace Practica001.Data;

public class AppDbContext : DbContext 
{
    public AppDbContext(DbContextOptions<AppDbContext> options) 
        : base(options)
    { 
    
    }


    public DbSet<Usuario> Usuarios { get; set; }
    public DbSet<TokenUsuario> Tokens { get; set; }
    public DbSet<Rol> Roles { get; set; }

    public DbSet<Product> Products { get; set; }
    public DbSet<Category> Categories { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Usuario>().Property(u => u.UsuarioNombre).HasColumnName("Usuario");
        modelBuilder.Entity<Category>().Property(c => c.Name).HasColumnName("Names");
        modelBuilder.Entity<Rol>().Property(r => r.RolNombre).HasColumnName("Rol");
    }

}
