-- =====================================================================
--  美股交易日记 — Supabase 建表脚本
--  用法：Supabase 控制台 → 左侧 SQL Editor → New query → 全部粘贴 → Run
--  本脚本可重复运行，不会报错、不会清空已有数据。
-- =====================================================================

-- 1) 交易记录表
create table if not exists public.trades (
  id         bigint primary key,                       -- 客户端用 Date.now() 生成
  date       text   not null,                          -- 'YYYY-MM-DD'
  type       text   not null check (type in ('buy','sell')),
  ticker     text   not null,
  qty        numeric not null,
  price      numeric not null,
  fee        numeric not null default 0,
  total      numeric,
  pnl        numeric,                                   -- 买入为 NULL，卖出为已实现盈亏
  created_at timestamptz default now()
);

-- 2) 资金流水表
create table if not exists public.cashflows (
  id         bigint primary key,
  date       text   not null,
  type       text   not null check (type in ('in','out')),
  amount     numeric not null,
  note       text,
  created_at timestamptz default now()
);

-- 3) 开启行级安全（RLS）
alter table public.trades    enable row level security;
alter table public.cashflows enable row level security;

-- 4) 访问策略
--    因为本应用用「客户端 PIN 码」做门禁、没有 Supabase 登录，
--    所以这里允许匿名 anon 角色读写两张表（与你选择的方案一致）。
--    若以后想升级为真正的账号登录，把下面策略换成基于 auth.uid() 的即可。
drop policy if exists "allow all on trades"    on public.trades;
drop policy if exists "allow all on cashflows" on public.cashflows;
create policy "allow all on trades"    on public.trades    for all using (true) with check (true);
create policy "allow all on cashflows" on public.cashflows for all using (true) with check (true);

-- 5) 打开实时订阅（Mac / 手机自动同步靠它）
--    若表已在 publication 中，重复运行会安全跳过。
do $$
begin
  begin
    alter publication supabase_realtime add table public.trades;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.cashflows;
  exception when duplicate_object then null;
  end;
end $$;

-- 完成。可在 Table Editor 看到 trades / cashflows 两张表。
