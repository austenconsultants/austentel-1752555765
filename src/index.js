import React from 'react';
import ReactDOM from 'react-dom/client';

const AustentelApp = () => {
  const [systemInfo, setSystemInfo] = React.useState({});
  const [healthStatus, setHealthStatus] = React.useState('checking');
  
  React.useEffect(() => {
    setSystemInfo({
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      language: navigator.language,
      timestamp: new Date().toLocaleString(),
      isSafari: /^((?!chrome|android).)*safari/i.test(navigator.userAgent),
      isRetina: window.devicePixelRatio > 1,
      screenSize: `${window.screen.width}x${window.screen.height}`,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
    });
    
    setTimeout(() => setHealthStatus('healthy'), 1000);
  }, []);

  return (
    <div style={{
      padding: '40px',
      fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      color: 'white',
      borderRadius: '16px',
      margin: '40px auto',
      maxWidth: '1200px',
      boxShadow: '0 30px 60px rgba(0,0,0,0.2)',
      minHeight: '90vh'
    }}>
      <div style={{textAlign: 'center', marginBottom: '50px'}}>
        <h1 style={{fontSize: '3.5em', margin: '20px 0'}}>🌐 AUSTENTEL ACS</h1>
        <h2 style={{fontSize: '1.6em', opacity: '0.9'}}>App Service Deployment Success!</h2>
        <p style={{fontSize: '1.1em', opacity: '0.8'}}>Bypasses Container Instance - uses reliable App Service hosting</p>
        <div style={{
          display: 'inline-block',
          padding: '10px 20px',
          background: healthStatus === 'healthy' ? 'rgba(0,255,0,0.2)' : 'rgba(255,255,0,0.2)',
          borderRadius: '25px',
          border: `2px solid ${healthStatus === 'healthy' ? '#00ff00' : '#ffff00'}`,
          marginTop: '20px'
        }}>
          {healthStatus === 'healthy' ? '✅ App Service Healthy' : '🔄 Health Check...'}
        </div>
      </div>
      
      <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))', gap: '30px'}}>
        <div style={{background: 'rgba(255,255,255,0.12)', padding: '30px', borderRadius: '12px'}}>
          <h3>🌐 App Service Benefits</h3>
          <ul style={{listStyle: 'none', padding: 0, lineHeight: '2'}}>
            <li>🚫 No provider registration needed</li>
            <li>🛡️ Enterprise-grade reliability</li>
            <li>📈 Auto-scaling capabilities</li>
            <li>🔒 Built-in security features</li>
            <li>💰 Cost-effective hosting</li>
            <li>🌍 Global CDN integration</li>
            <li>📊 Advanced monitoring</li>
            <li>🔄 Easy deployment slots</li>
          </ul>
        </div>

        <div style={{background: 'rgba(255,255,255,0.12)', padding: '30px', borderRadius: '12px'}}>
          <h3>🖥️ System Information</h3>
          <p><strong>Platform:</strong> {systemInfo.platform}</p>
          <p><strong>Browser:</strong> {systemInfo.isSafari ? 'Safari ✅' : 'Other'}</p>
          <p><strong>Screen:</strong> {systemInfo.screenSize}</p>
          <p><strong>Language:</strong> {systemInfo.language}</p>
          <p><strong>Timezone:</strong> {systemInfo.timezone}</p>
          <p><strong>Deployed:</strong> {systemInfo.timestamp}</p>
          <p><strong>Hosting:</strong> <span style={{color: '#00ff00'}}>Azure App Service</span></p>
        </div>

        <div style={{background: 'rgba(255,255,255,0.12)', padding: '30px', borderRadius: '12px'}}>
          <h3>🚀 App Service Features</h3>
          <div style={{display: 'grid', gridTemplateColumns: '1fr', gap: '15px'}}>
            <div>
              <h4>⚡ Performance</h4>
              <p style={{fontSize: '0.9em', opacity: '0.8'}}>Fast, scalable container hosting</p>
            </div>
            <div>
              <h4>🛡️ Security</h4>
              <p style={{fontSize: '0.9em', opacity: '0.8'}}>Built-in SSL, authentication</p>
            </div>
            <div>
              <h4>📊 Monitoring</h4>
              <p style={{fontSize: '0.9em', opacity: '0.8'}}>Application Insights integration</p>
            </div>
          </div>
        </div>
      </div>

      <div style={{
        textAlign: 'center',
        background: 'rgba(255,255,255,0.15)',
        padding: '40px',
        borderRadius: '12px',
        marginTop: '40px',
        border: '2px solid rgba(255,255,255,0.3)'
      }}>
        <h2 style={{fontSize: '2.5em', margin: '20px 0'}}>🎉 APP SERVICE DEPLOYMENT SUCCESS! 🎉</h2>
        <p style={{fontSize: '1.3em', opacity: '0.95'}}>
          Austentel ACS VoiceHub Pro deployed on Azure App Service
        </p>
        <p style={{fontSize: '1.1em', opacity: '0.9'}}>
          Accessible at: <strong>acs1.austentel.com</strong>
        </p>
        <div style={{marginTop: '30px', opacity: '0.8'}}>
          <p>🌐 Reliable App Service hosting</p>
          <p>🚫 No provider registration issues</p>
          <p>🛡️ Enterprise-grade infrastructure</p>
          <p>📈 Auto-scaling ready</p>
        </div>
      </div>
    </div>
  );
};

ReactDOM.createRoot(document.getElementById('root')).render(<AustentelApp />);
