import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

const AdminCredentials = () => {
  const [adminUser, setAdminUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkAdmin = async () => {
      try {
        const { data: { users }, error } = await supabase.auth.admin.listUsers();
        if (error) throw error;
        
        // As defined in create_admin_external.sql
        const targetEmail = 'admin@bivvo.com.br';
        const found = users.find(u => u.email === targetEmail);
        setAdminUser(found);
      } catch (err) {
        console.error("Error fetching users:", err);
      } finally {
        setLoading(false);
      }
    };

    // checkAdmin(); // This would require service role, which we don't have client-side
    setLoading(false);
  }, []);

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
            <p>Se o usuário ainda não foi criado, você pode executar o script SQL no editor do backend.</p>
          </div>

          <a 
            href="/login" 
            className="block w-full text-center bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 rounded-xl transition-all shadow-lg shadow-blue-200"
          >
            Ir para Login
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
