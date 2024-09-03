# AnyNote

AnyNote is an open-source, cross-platform note-taking application that puts your data in your hands.

![demo.gif](https://anynote.online/screenshot/show.gif)

[![GitHub Repository](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/ychisbest/AnyNote)
[![Website](https://img.shields.io/badge/Website-anynote.online-blue)](https://anynote.online)

## Features

- **Self-hosted**: Deploy AnyNote on your own infrastructure and keep your data under your control.
- **Cross-platform**: Supports Windows, Android, and Web platforms.
- **WYSIWYG Markdown Editor**: Enjoy an excellent editing experience with a what-you-see-is-what-you-get Markdown editor.
- **Real-time Synchronization**: Automatically sync data across all open clients.
- **Efficient Search**: Find your historical notes instantly with high-performance search capabilities.

## Getting Started

### Backend Deployment

To deploy the AnyNote backend using Docker, run the following command:

```bash
docker run -d -p 8080:8080 -e secret=YOUR_SECRET -v /path/to/data:/data ych8398527/anynote:1.0
```

Replace `YOUR_SECRET` with your chosen secret key and `/path/to/data` with the desired path for data storage.

### Client Installation

Download the latest client for your platform from our [GitHub Releases](https://github.com/ychisbest/AnyNote/releases) page.

## Contributing

We welcome contributions to AnyNote! Please check out our [GitHub repository](https://github.com/ychisbest/AnyNote) for more information on how to get involved.

## Support

For more information and support, visit our [official website](https://anynote.online) or open an issue on our GitHub repository.

---

AnyNote - Your notes, your way, anywhere.