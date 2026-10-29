using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Practica001.Data;
using Practica001.Models;

namespace Practica001.Controllers;

[ApiController]
[TokenAuth]
[Route("api/[controller]")]
public class CategoryController : ControllerBase
{
    private readonly AppDbContext _appDbContext;

    public CategoryController(AppDbContext appDbContext)
    {
        _appDbContext = appDbContext;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Category>>> GetCategories()
    {
        return await _appDbContext.Categories.ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Category>> GetCategoryById(int id)
    {
        var category = await _appDbContext.Categories.FindAsync(id);

        if (category == null)
        {
            return NotFound();
        }

        return category;
    }

    [HttpPost()]
    public async Task<ActionResult<Category>> CreateCategory(Category category)
    {
        _appDbContext.Categories.Add(category);
        await _appDbContext.SaveChangesAsync();

        return CreatedAtAction(
            nameof(GetCategoryById),
            new { id = category.Id },
            category);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateCategory(int id, Category category)
    {
        if (id != category.Id)
        {
            return BadRequest();
        }

        var existingCategory = await _appDbContext.Categories
            .FirstOrDefaultAsync(c => c.Id == id);

        if (existingCategory == null)
        {
            return NotFound();
        }

        if (existingCategory.version != category.version)
        {
            return Conflict(new
            {
                message = "La categoría fue actualizada por otro usuario.",
                versionActual = existingCategory.version,
                versionEnviada = category.version
            });
        }

        existingCategory.Name = category.Name;
        existingCategory.version++;

        try
        {
            await _appDbContext.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            return Conflict(new
            {
                message = "La categoría fue actualizada por otro usuario."
            });
        }

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteCategory(int id)
    {
        var category = await _appDbContext.Categories.FindAsync(id);
        if (category == null)
        {
            return NotFound();
        }

        _appDbContext.Categories.Remove(category);
        await _appDbContext.SaveChangesAsync();

        return NoContent();
    }
}
