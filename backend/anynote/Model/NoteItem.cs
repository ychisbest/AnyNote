namespace anynote.Model
{
    public class NoteItem
    {
        public int Id { get; set; }

        public bool IsTopMost { get; set; }

        public string? Content { get; set; }

        public DateTime CreateTime { get; set; }

        public DateTime? LastUpdateTime { get; set; }

        public DateTime? ArchiveTime { get; set; }

        public bool IsArchived { get; set; }

        public int? Color { get; set; }

        public int Index { get; set; }
    }
}
