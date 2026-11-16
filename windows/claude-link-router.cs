using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System.Threading;

[assembly: AssemblyTitle("Claude Link Router")]
[assembly: AssemblyProduct("Claude Link Router")]

static class Router
{
    delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] static extern int GetWindowTextLength(IntPtr h);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);

    static readonly string Local = Environment.GetEnvironmentVariable("LOCALAPPDATA");
    static readonly string Alias = Path.Combine(Local, @"Microsoft\WindowsApps\claude-desktop.exe");
    static readonly string LogFile = Path.Combine(Local, "claude-link-router.log");
    static readonly Regex DataDirArg = new Regex("--user-data-dir=(\"[^\"]*\"|\\S+)");

    static int Main(string[] args)
    {
        if (args.Length != 1 || !args[0].StartsWith("claude:", StringComparison.OrdinalIgnoreCase)) return 2;
        string url = args[0].Replace("\"", "%22");

        string[] found = null;
        var scan = new Thread(delegate () { try { found = TopmostClaude(); } catch (Exception) { } });
        scan.IsBackground = true;
        scan.Start();
        string[] hit = scan.Join(3000) ? found : null;
        string dir = hit == null ? null : hit[1];

        string exe = hit != null && !IsPackaged(hit[0]) ? hit[0] : Alias;

        int cut = url.IndexOfAny(new[] { '?', '#' });
        Log((cut < 0 ? url : url.Substring(0, cut)) + " -> " + (dir ?? "original"));

        try
        {
            var psi = new ProcessStartInfo(exe);
            psi.Arguments = (dir == null ? "" : "--user-data-dir=" + Quote(dir) + " ") + Quote(url);
            psi.UseShellExecute = false;
            Process.Start(psi);
        }
        catch (Exception e) { Log("start failed: " + e.Message); return 1; }
        return 0;
    }

    static string Quote(string s) { return "\"" + Regex.Replace(s, @"(\\+)$", "$1$1") + "\""; }

    static bool IsPackaged(string exe)
    {
        return exe.IndexOf(@"\WindowsApps\Claude_", StringComparison.OrdinalIgnoreCase) >= 0;
    }

    static string[] TopmostClaude()
    {
        Dictionary<uint, string[]> mains = ClaudeMains();
        string[] result = null;
        EnumWindows(delegate (IntPtr h, IntPtr _)
        {
            if (!IsWindowVisible(h) || GetWindowTextLength(h) == 0) return true;
            uint pid;
            GetWindowThreadProcessId(h, out pid);
            string[] p;
            if (!mains.TryGetValue(pid, out p)) return true;
            Match m = DataDirArg.Match(p[1]);
            result = new[] { p[0], m.Success ? m.Groups[1].Value.Trim('"') : null };
            return false;
        }, IntPtr.Zero);
        return result;
    }

    static Dictionary<uint, string[]> ClaudeMains()
    {
        string copies = Path.Combine(Environment.GetEnvironmentVariable("USERPROFILE"), ".claude-instances") + "\\";
        var map = new Dictionary<uint, string[]>();
        using (var q = new ManagementObjectSearcher("SELECT ProcessId, ExecutablePath, CommandLine FROM Win32_Process WHERE Name='Claude.exe'"))
        foreach (ManagementObject o in q.Get())
        {
            string exe = (o["ExecutablePath"] as string) ?? "";
            string cmd = (o["CommandLine"] as string) ?? "";
            bool packaged = IsPackaged(exe) && exe.EndsWith(@"\app\Claude.exe", StringComparison.OrdinalIgnoreCase);
            bool copy = exe.StartsWith(copies, StringComparison.OrdinalIgnoreCase);
            if ((packaged || copy) && !cmd.Contains("--type=")) map[(uint)o["ProcessId"]] = new[] { exe, cmd };
        }
        return map;
    }

    static void Log(string line)
    {
        try
        {
            if (File.Exists(LogFile) && new FileInfo(LogFile).Length > 256 * 1024) File.Delete(LogFile);
            File.AppendAllText(LogFile, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss ") + line + Environment.NewLine);
        }
        catch (Exception) { }
    }
}
