﻿// NotesController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using anynote.Model;
using anynote.Model.Request;
using Microsoft.AspNetCore.SignalR;
using anynote.Hubs;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory.Database;
using System.Text;
using anynote.Attributes;

namespace anynote.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NotesController : ControllerBase
    {
        private readonly NoteDbContext _context;
        private readonly IHubContext<NoteHub> _hubContext;

        public NotesController(NoteDbContext context, IHubContext<NoteHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        [HttpGet]
        [SecretHeader]
        public async Task<ActionResult<IEnumerable<NoteItem>>> GetNotes()
        {
            return await _context.Notes.ToListAsync();
        }

        [HttpPut("{id}")]
        [SecretHeader]
        public async Task<ActionResult<NoteItem>> PutNoteItem(int id, NoteItem noteItem)
        {
            var singalrid = Request.Headers["SignalR-ConnectionId"];

            if (id != noteItem.Id)
            {
                return BadRequest();
            }

            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var existingNoteItem = await _context.Notes.FindAsync(id);
            if (existingNoteItem == null)
            {
                return NotFound();
            }

            if (noteItem.Content != existingNoteItem.Content)
            {
                noteItem.LastUpdateTime = DateTime.UtcNow;
            }

            _context.Entry(existingNoteItem).CurrentValues.SetValues(noteItem);

            try
            {
                await _context.SaveChangesAsync();
                await _hubContext.Clients.AllExcept(singalrid).SendAsync("ReceiveNoteUpdate", noteItem);
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!NoteItemExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }
            return noteItem;
        }

        [HttpPost("UpdateIndex")]
        [SecretHeader]
        public async Task<IActionResult> UpdateIndex([FromBody] UpdateIndexDto dto)
        {
            var singalrid = Request.Headers["SignalR-ConnectionId"];

            if (dto.Ids == null || dto.Indices == null || dto.Ids.Length != dto.Indices.Length)
            {
                return BadRequest("The arrays of ids and indices must have the same length.");
            }

            var notes = await _context.Notes.Where(n => dto.Ids.Contains(n.Id)).ToListAsync();

            if (notes.Count != dto.Ids.Length)
            {
                return BadRequest("One or more note IDs are invalid.");
            }

            for (int i = 0; i < dto.Ids.Length; i++)
            {
                var note = notes.First(n => n.Id == dto.Ids[i]);
                note.Index = dto.Indices[i];
            }

            try
            {
                await _context.SaveChangesAsync();
                await _hubContext.Clients.AllExcept(singalrid).SendAsync("ReceiveNoteIndicesUpdate", dto.Ids, dto.Indices);
                return Ok("Note indices updated successfully.");
            }
            catch (DbUpdateException)
            {
                return StatusCode(500, "An error occurred while updating note indices.");
            }
        }

        [HttpPost("add")]
        [SecretHeader]
        public async Task<ActionResult<NoteItem>> AddNote()
        {
            var singalrid = Request.Headers["SignalR-ConnectionId"];

            var note = new NoteItem();
            note.CreateTime = DateTime.UtcNow;
            _context.Notes.Add(note);
            await _context.SaveChangesAsync();
            await _hubContext.Clients.AllExcept(singalrid).SendAsync("ReceiveNewNote", note);
            return note;
        }

        [HttpPost("Archieve")]
        [SecretHeader]
        public async Task<ActionResult> AchieveItem(int id)
        {
            var singalrid = Request.Headers["SignalR-ConnectionId"];

            var noteItem = await _context.Notes.FindAsync(id);
            if (noteItem == null)
            {
                return NotFound();
            }

            noteItem.ArchiveTime = DateTime.UtcNow;
            noteItem.IsArchived = true;

            await _context.SaveChangesAsync();
            await _hubContext.Clients.AllExcept(singalrid).SendAsync("ReceiveNoteArchive", id);

            return NoContent();
        }

        [HttpPost("UnArchieve")]
        [SecretHeader]
        public async Task<ActionResult> UnAchieveItem(int id)
        {
            var singalrid = Request.Headers["SignalR-ConnectionId"];

            var noteItem = await _context.Notes.FindAsync(id);
            if (noteItem == null)
            {
                return NotFound();
            }

            noteItem.ArchiveTime = null;
            noteItem.IsArchived = false;

            await _context.SaveChangesAsync();
            await _hubContext.Clients.AllExcept(singalrid).SendAsync("ReceiveNoteUnarchive", id);

            return NoContent();
        }

        [HttpDelete("{id}")]
        [SecretHeader]
        public async Task<IActionResult> DeleteNoteItem(int id)
        {
            var singalrid = Request.Headers["SignalR-ConnectionId"];
            var noteItem = await _context.Notes.FindAsync(id);
            if (noteItem == null)
            {
                return NotFound();
            }

            _context.Notes.Remove(noteItem);
            await _context.SaveChangesAsync();
            await _hubContext.Clients.AllExcept(singalrid).SendAsync("ReceiveNoteDelete", id);

            return NoContent();
        }

        [HttpGet("/")]
        public async Task<ContentResult> Index()
        {
            var content = @"<!DOCTYPE html>
<html lang=""zh-CN"">
<head>
    <meta charset=""UTF-8"">
    <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
    <title>AnyNote 部署成功</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background-color: #f0f2f5;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            background-color: white;
            padding: 2rem;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        h1 {
            color: #4caf50;
            margin-bottom: 1rem;
        }
        p {
            color: #333;
            margin-bottom: 1.5rem;
        }
        .icon {
            font-size: 4rem;
            margin-bottom: 1rem;
        }
    </style>
</head>
<body>
    <div class=""container"">
        <div class=""icon"">✅</div>
        <h1>AnyNote 部署成功</h1>
        <p>您的 AnyNote 服务器程序已成功部署。<br>现在您可以开始使用了。</p>
    </div>
</body>
</html>";

            return Content(content,"text/html",Encoding.UTF8);
        }

        private bool NoteItemExists(int id)
        {
            return _context.Notes.Any(e => e.Id == id);
        }
    }
}