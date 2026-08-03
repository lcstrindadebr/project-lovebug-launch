import { useState } from "react";

const AdminCredentials = () => {
  return (
    <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center p-6 text-slate-900 font-sans">
      <div className="max-w-md w-full bg-white rounded-2xl shadow-xl p-8 border border-slate-100">
        <h1 className="text-2xl font-bold text-slate-800 mb-6 text-center">Bivvo Admin</h1>
        
        <div className="space-y-6">
          <div className="p-4 bg-blue-50 rounded-lg border border-blue-100">
            <h2 className="text-sm font-semibold text-blue-700 uppercase tracking-wider mb-2">Credenciais Padrão</h2>
            <div className="space-y-3">
              <div>
                <p className="text-xs text-slate-500 mb-1">E-mail</p>
                <p className="font-mono text-sm bg-white p-2 rounded border border-blue-200 select-all">admin@bivvo.com.br</p>
              </div>
              <div>
                <p className="text-xs text-slate-500 mb-1">Senha</p>
                <p className="font-mono text-sm bg-white p-2 rounded border border-blue-200 select-all">@Skol6678</p>
              </div>
            </div>
          </div>

          <div className="text-sm text-slate-600 space-y-2">
            <p>Estas são as credenciais definidas no arquivo <code className="bg-slate-100 px-1 rounded">create_admin_external.sql</code>.</p>
            <p>Certifique-se de que o backend foi provisionado com estas credenciais.</p>
          </div>

          <a 
            href="/" 
            className="block w-full text-center bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 rounded-xl transition-all shadow-lg shadow-blue-200"
          >
            Voltar para Início
          </a>
        </div>
      </div>
      
      <footer className="mt-8 text-slate-400 text-xs">
        Bivvo Payment System &bull; 2026
      </footer>
    </div>
  );
};

export default AdminCredentials;

