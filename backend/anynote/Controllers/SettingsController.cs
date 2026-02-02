using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using anynote.Model;
using anynote.Attributes;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace anynote.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SettingsController : ControllerBase
    {
        private readonly NoteDbContext _context;

        public SettingsController(NoteDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        [SecretHeader]
        public async Task<ActionResult<Dictionary<string, string?>>> GetSettings()
        {
            var items = await _context.Settings.ToListAsync();
            var result = items.ToDictionary(item => item.Key, item => item.Value);
            return Ok(result);
        }

        [HttpGet("{key}")]
        [SecretHeader]
        public async Task<ActionResult<SettingItem>> GetSetting(string key)
        {
            var item = await _context.Settings.FindAsync(key);
            if (item == null)
            {
                return NotFound();
            }
            return Ok(item);
        }

        [HttpPut]
        [SecretHeader]
        public async Task<IActionResult> PutSettings([FromBody] Dictionary<string, string?> settings)
        {
            if (settings == null || settings.Count == 0)
            {
                return BadRequest("Settings cannot be empty.");
            }

            var keys = settings.Keys.ToList();
            var existingItems = await _context.Settings
                .Where(s => keys.Contains(s.Key))
                .ToListAsync();

            var existingMap = existingItems.ToDictionary(item => item.Key, item => item);

            foreach (var kv in settings)
            {
                if (existingMap.TryGetValue(kv.Key, out var existing))
                {
                    existing.Value = kv.Value;
                }
                else
                {
                    _context.Settings.Add(new SettingItem
                    {
                        Key = kv.Key,
                        Value = kv.Value
                    });
                }
            }

            await _context.SaveChangesAsync();
            return NoContent();
        }

        public class SettingValueDto
        {
            public string? Value { get; set; }
        }

        [HttpPut("{key}")]
        [SecretHeader]
        public async Task<ActionResult<SettingItem>> PutSetting(string key, [FromBody] SettingValueDto dto)
        {
            var existing = await _context.Settings.FindAsync(key);
            if (existing == null)
            {
                var created = new SettingItem { Key = key, Value = dto.Value };
                _context.Settings.Add(created);
                await _context.SaveChangesAsync();
                return Ok(created);
            }

            existing.Value = dto.Value;
            await _context.SaveChangesAsync();
            return Ok(existing);
        }

        [HttpDelete("{key}")]
        [SecretHeader]
        public async Task<IActionResult> DeleteSetting(string key)
        {
            var existing = await _context.Settings.FindAsync(key);
            if (existing == null)
            {
                return NotFound();
            }

            _context.Settings.Remove(existing);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
