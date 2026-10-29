
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Practica001.Data;
using Practica001.Models;

namespace Practica001.Controllers;

[ApiController]
[TokenAuth]
[Route("api/[controller]")]
public class ProductController : ControllerBase
{
    private readonly AppDbContext _appDbContext;

    public ProductController(AppDbContext appDbContext)
    {
        _appDbContext = appDbContext;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Product>>> GetProducts()
    {
        return await _appDbContext.Products.ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Product>> GetProductbyId(int id)
    {
        var product = await _appDbContext.Products
            .FirstOrDefaultAsync(p => p.Id == id);

        if (product == null)
        {
            return NotFound();
        }

        return product;
    }

    [HttpPost]
    public async Task<ActionResult<Product>> CreateProduct(Product product)
    {
        _appDbContext.Products.Add(product);
        await _appDbContext.SaveChangesAsync();

        return CreatedAtAction(
            nameof(GetProductbyId),
            new { id = product.Id },
            product
        );
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateProduct(int id, Product product)
    {
        if (id != product.Id)
        {
            return BadRequest();
        }

        var existingProduct = await _appDbContext.Products
            .FirstOrDefaultAsync(p => p.Id == id);

        if (existingProduct == null)
        {
            return NotFound();
        }

        // Verificamos la versión
        if (existingProduct.version != product.version)
        {
            return Conflict(new
            {
                message = "El producto fue actualizado por otro usuario.",
                versionActual = existingProduct.version,
                versionEnviada = product.version
            });
        }

        // Actualizamos los datos
        existingProduct.Names = product.Names;
        existingProduct.Price = product.Price;
        existingProduct.Stock = product.Stock;
        existingProduct.Descriptions = product.Descriptions;
        existingProduct.IsActive = product.IsActive;

        existingProduct.ImageUrl = product.ImageUrl;

        // Incrementamos la versión
        existingProduct.version++;

        try
        {
            await _appDbContext.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            return Conflict(new
            {
                message = "El producto fue actualizado por otro usuario."
            });
        }

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteProduct(int id)
    {
        var product = await _appDbContext.Products.FindAsync(id);

        if (product == null)
        {
            return NotFound();
        }

        _appDbContext.Products.Remove(product);
        await _appDbContext.SaveChangesAsync();

        return NoContent();
    }
}

