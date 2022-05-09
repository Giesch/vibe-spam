create table chat_messages (
  id uuid primary key default uuid_generate_v4(),
  room_id uuid references rooms (id) not null,
  author_session_id uuid not null,
  content text not null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

select manage_updated_at('chat_messages');
