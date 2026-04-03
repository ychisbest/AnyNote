using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.Extensions.Options;
using ZstdSharp;

namespace anynote.Compression;

public sealed class ZstdCompressionProviderOptions
{
    public int Level { get; set; } = 1;
}

public sealed class ZstdCompressionProvider(IOptions<ZstdCompressionProviderOptions> options) : ICompressionProvider
{
    private readonly ZstdCompressionProviderOptions _options = options.Value;

    public string EncodingName => "zstd";

    public bool SupportsFlush => true;

    public Stream CreateStream(Stream outputStream) => new CompressionStream(outputStream, _options.Level);
}
