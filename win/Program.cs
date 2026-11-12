using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Web.Script.Serialization;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace RamanXcAnalyzer
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    class MainForm : Form
    {
        readonly WebView2 web = new WebView2 { Dock = DockStyle.Fill };

        public MainForm()
        {
            Text = "Raman Xc Analyzer";
            ClientSize = new Size(1500, 900);
            StartPosition = FormStartPosition.CenterScreen;
            try { Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath); } catch { }
            Controls.Add(web);
            Load += async (s, e) => await InitAsync();
        }

        async System.Threading.Tasks.Task InitAsync()
        {
            try
            {
                var data = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "RamanXcAnalyzer");
                var env = await CoreWebView2Environment.CreateAsync(null, data);
                await web.EnsureCoreWebView2Async(env);
            }
            catch (WebView2RuntimeNotFoundException)
            {
                if (MessageBox.Show("The Microsoft Edge WebView2 Runtime is missing.\nOpen the download page?", Text,
                        MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
                    Process.Start(new ProcessStartInfo("https://developer.microsoft.com/microsoft-edge/webview2/") { UseShellExecute = true });
                Close();
                return;
            }
            var core = web.CoreWebView2;
            core.SetVirtualHostNameToFolderMapping("app.local",
                Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "app"), CoreWebView2HostResourceAccessKind.Allow);
            core.WebMessageReceived += OnMessage;
            core.Navigate("https://app.local/index.html");
        }

        // Messages from the page: {cmd:'save', name, b64} or {cmd:'copy', b64}
        void OnMessage(object sender, CoreWebView2WebMessageReceivedEventArgs e)
        {
            try
            {
                var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
                var m = js.Deserialize<Dictionary<string, object>>(e.WebMessageAsJson);
                var cmd = m["cmd"] as string;
                var bytes = Convert.FromBase64String(m["b64"] as string);
                if (cmd == "copy")
                {
                    using (var ms = new MemoryStream(bytes))
                    using (var img = Image.FromStream(ms))
                        Clipboard.SetImage(new Bitmap(img));
                }
                else if (cmd == "save")
                {
                    var name = (m.ContainsKey("name") ? m["name"] as string : null) ?? "export";
                    var ext = Path.GetExtension(name);
                    using (var dlg = new SaveFileDialog { FileName = name, Filter = (ext.Length > 1 ? ext.Substring(1).ToUpper() + " file|*" + ext + "|" : "") + "All files|*.*" })
                        if (dlg.ShowDialog(this) == DialogResult.OK) File.WriteAllBytes(dlg.FileName, bytes);
                }
            }
            catch (Exception ex) { MessageBox.Show(ex.Message, Text); }
        }
    }
}
