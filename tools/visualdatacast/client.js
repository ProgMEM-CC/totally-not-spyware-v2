/*
 VisualDataCast client (drop-in)
 - Minimal dependency-free sender that runs in any modern browser, iOS 12 friendly
 - Streams still frames + audit issues to VisualDataCast server

 Usage:
   const vdc = new VisualDataCast('http://<server-ip>:3344');
   await vdc.start({ url: location.href });
   await vdc.beginLoop(); // records ~6s by default; adjust opts
   await vdc.stop();

 Optional: Inject your own auditor by setting window.tnsAudit = () => Issue[]
*/

(function(global){
  class VisualDataCast {
    constructor(serverBase){
      this.serverBase = serverBase.replace(/\/$/, '');
      this.sessionId = null;
      this._loop = null;
      this._running = false;
      this._intervalMs = 100;
      this._durationMs = 6000;
    }

    async start(meta){
      const r = await fetch(`${this.serverBase}/vdc/start`,{
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ meta })
      });
      const j = await r.json();
      this.sessionId = j.id;
      return this.sessionId;
    }

    async sendFrame(blob){
      if (!this.sessionId || !blob) return;
      const fd = new FormData();
      fd.append('id', this.sessionId);
      fd.append('ts', Date.now());
      fd.append('frame', blob, 'f.webp');
      await fetch(`${this.serverBase}/vdc/frame`,{ method:'POST', body: fd });
    }

    async sendIssues(issues, meta){
      if (!this.sessionId) return;
      await fetch(`${this.serverBase}/vdc/issues`,{
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ id: this.sessionId, issues, meta })
      });
    }

    async stop(){
      if (!this.sessionId) return;
      this._running = false;
      if (this._loop){
        clearInterval(this._loop);
        this._loop = null;
      }
      const r = await fetch(`${this.serverBase}/vdc/stop`,{
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ id: this.sessionId })
      });
      return await r.json();
    }

    configure(opts){
      if (!opts) return;
      if (typeof opts.intervalMs === 'number') this._intervalMs = opts.intervalMs;
      if (typeof opts.durationMs === 'number') this._durationMs = opts.durationMs;
    }

    async captureWebp(){
      const width = Math.max(320, Math.min(1920, window.innerWidth || document.documentElement.clientWidth || 640));
      const height = Math.max(240, Math.min(1080, window.innerHeight || document.documentElement.clientHeight || 480));
      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext('2d');
      ctx.fillStyle = '#ffffff';
      ctx.fillRect(0,0,width,height);
      // Optional: draw key UI elements as simple boxes with labels for iOS12 fallback
      try {
        const main = document.querySelector('#app, #main, body');
        if (main) {
          const r = main.getBoundingClientRect();
          ctx.fillStyle = '#e3e7ef';
          ctx.fillRect(0, 0, width, 48);
          ctx.fillStyle = '#222';
          ctx.font = '16px -apple-system, system-ui, sans-serif';
          ctx.fillText(document.title || 'VisualDataCast', 12, 30);
          ctx.strokeStyle = '#4096ff';
          ctx.strokeRect(Math.max(0, r.left), Math.max(0, r.top), Math.min(width, r.width), Math.min(height, r.height));
        }
      } catch(_){}
      return await new Promise((res) => canvas.toBlob((b)=>res(b), 'image/webp', 0.9));
    }

    currentAudit(){
      try {
        if (typeof global.tnsAudit === 'function') return global.tnsAudit() || [];
      } catch(_){}
      return [];
    }

    async beginLoop(opts){
      this.configure(opts);
      this._running = true;
      const startAt = Date.now();
      const tick = async () => {
        if (!this._running) return;
        const blob = await this.captureWebp();
        try {
          await this.sendFrame(blob);
          const issues = this.currentAudit();
          await this.sendIssues(issues, { t: Date.now() });
        } catch(_){}
        if (Date.now() - startAt >= this._durationMs) {
          await this.stop();
          if (typeof global.visualDataCastFinished === 'function') global.visualDataCastFinished();
        }
      };
      // immediate first tick
      tick();
      this._loop = setInterval(tick, this._intervalMs);
    }
  }

  global.VisualDataCast = VisualDataCast;
})(window);


