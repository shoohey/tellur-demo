// ============================================================
// TELLUR 設定ファイル
// Supabase プロジェクトの情報をここに入力してください
// ============================================================

const TELLUR_CONFIG = {
  // Supabase プロジェクト URL（例: https://xxxxx.supabase.co）
  SUPABASE_URL: '',

  // Supabase Anon Key（公開キー）
  SUPABASE_ANON_KEY: '',

  // アプリ名
  APP_NAME: 'TELLUR',

  // デモモード（Supabase未設定時はtrue → localStorageで動作）
  get DEMO_MODE() {
    return !this.SUPABASE_URL || !this.SUPABASE_ANON_KEY;
  }
};
