using anynote.Model;
using Microsoft.EntityFrameworkCore;

namespace anynote
{
    public class NoteDbContext : DbContext
    {
        public DbSet<NoteItem> Notes { get; set; }
        public DbSet<SettingItem> Settings { get; set; }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<NoteItem>().HasKey(t => t.Id);
            modelBuilder.Entity<NoteItem>().HasIndex(t => t.CreateTime);
            modelBuilder.Entity<NoteItem>().HasIndex(t => t.LastUpdateTime);
            //modelBuilder.Entity<NoteItem>().HasIndex(t => t.Content);
            modelBuilder.Entity<NoteItem>().HasIndex(t => t.IsArchived);

            modelBuilder.Entity<SettingItem>().HasKey(t => t.Key);

        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {

            var path = "/data/data.db";
            //var path = "data.db";
            optionsBuilder.UseSqlite("Data Source=" + path);
            base.OnConfiguring(optionsBuilder);
        }
    }
}
