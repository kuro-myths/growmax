using System.Net.Http;
using System.Text;
using System.Text.Json;

namespace GrowCraft.Client.Networking;

/// <summary>
/// REST client ke backend GrowCraft API (ASP.NET Core).
/// Phase 1: health check + login/register. Sinkronisasi farming penuh = Phase 5
/// (client saat ini menjalankan sim lokal yang rumusnya identik dengan server).
/// </summary>
public class ApiClient
{
    private readonly HttpClient _http = new();
    public string? Token { get; private set; }
    public bool Online { get; private set; }

    public ApiClient(string baseUrl)
    {
        _http.BaseAddress = new Uri(baseUrl.TrimEnd('/') + "/");
        _http.Timeout = TimeSpan.FromSeconds(3);
    }

    public async Task<bool> PingAsync()
    {
        try
        {
            var res = await _http.GetAsync("health");
            Online = res.IsSuccessStatusCode;
        }
        catch { Online = false; }
        return Online;
    }

    public async Task<(bool ok, string? token, string? error)> RegisterAsync(string username, string password)
    {
        var body = JsonSerializer.Serialize(new { username, password });
        var res = await _http.PostAsync("api/auth/register",
            new StringContent(body, Encoding.UTF8, "application/json"));
        var json = await res.Content.ReadAsStringAsync();
        if (!res.IsSuccessStatusCode)
            return (false, null, TryReadError(json));
        Token = JsonDocument.Parse(json).RootElement.GetProperty("token").GetString();
        Online = true;
        return (true, Token, null);
    }

    public async Task<(bool ok, string? token, string? error)> LoginAsync(string username, string password)
    {
        var body = JsonSerializer.Serialize(new { username, password });
        var res = await _http.PostAsync("api/auth/login",
            new StringContent(body, Encoding.UTF8, "application/json"));
        var json = await res.Content.ReadAsStringAsync();
        if (!res.IsSuccessStatusCode)
            return (false, null, TryReadError(json));
        Token = JsonDocument.Parse(json).RootElement.GetProperty("token").GetString();
        Online = true;
        return (true, Token, null);
    }

    private static string? TryReadError(string json)
    {
        try
        {
            using var doc = JsonDocument.Parse(json);
            if (doc.RootElement.TryGetProperty("error", out var err)) return err.GetString();
        }
        catch { }
        return json.Length > 120 ? json[..120] : json;
    }
}
