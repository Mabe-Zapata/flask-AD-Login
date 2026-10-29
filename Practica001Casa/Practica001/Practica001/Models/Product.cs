using System.ComponentModel.DataAnnotations;

namespace Practica001.Models;

public class Product
{
    public int Id { get; set; }
    public string Names { get; set; }

    public decimal Price { get; set; }

    public int Stock { get; set; } = 0;

    public int version { get; set; }

    public string Descriptions { get; set; }

    public string ImageUrl { get; set; }

    public bool IsActive { get; set; } = true;
}
