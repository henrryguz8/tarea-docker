// Modelos del chat

export interface User {
  id: string;
  name: string;
  avatarUrl: string;
  status: "online" | "offline";
}

export interface Message {
  id: string;
  senderId: string;
  content: string;
  createdAt: string;
  isSelf: boolean;
}

export interface Conversation {
  id: string;
  user: User;
  lastMessage: string;
  updatedAt: string;
  unreadCount?: number;
}
