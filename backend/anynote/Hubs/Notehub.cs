using Microsoft.AspNetCore.SignalR;
using anynote.Model;
using System;
using System.Threading.Tasks;

namespace anynote.Hubs
{
    public class NoteHub : Hub
    {
        private readonly ILogger<NoteHub> _logger;

        public NoteHub(ILogger<NoteHub> logger)
        {
            _logger = logger;
        }

        public override async Task OnConnectedAsync()
        {
            await base.OnConnectedAsync();
            _logger.LogInformation($"Client connected: {Context.ConnectionId}");
        }

        public override async Task OnDisconnectedAsync(Exception exception)
        {
            await base.OnDisconnectedAsync(exception);
            _logger.LogInformation($"Client disconnected: {Context.ConnectionId}. Reason: {exception?.Message ?? "Unknown"}");
        }


        public async Task UpdateNote(NoteItem note)
        {
            await Clients.AllExcept(Context.ConnectionId).SendAsync("ReceiveNoteUpdate", note);
        }

        public async Task ArchiveNote(int noteId)
        {
            await Clients.AllExcept(Context.ConnectionId).SendAsync("ReceiveNoteArchive", noteId);
        }

        public async Task UnarchiveNote(int noteId)
        {
            await Clients.AllExcept(Context.ConnectionId).SendAsync("ReceiveNoteUnarchive", noteId);
        }

        public async Task DeleteNote(int noteId)
        {
            await Clients.AllExcept(Context.ConnectionId).SendAsync("ReceiveNoteDelete", noteId);
        }

        public async Task AddNote(NoteItem note)
        {
            await Clients.AllExcept(Context.ConnectionId).SendAsync("ReceiveNewNote", note);
        }

        public async Task UpdateNoteIndices(int[] ids, int[] indices)
        {
            await Clients.AllExcept(Context.ConnectionId).SendAsync("ReceiveNoteIndicesUpdate", ids, indices);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                _logger.LogInformation($"NoteHub disposing for connection: {Context.ConnectionId}");
            }
            base.Dispose(disposing);
        }
    }
}