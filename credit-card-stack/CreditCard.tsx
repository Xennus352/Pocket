'use client';

import { type ReactNode, useState, useEffect, useCallback } from 'react';
import { motion, useMotionValue, useTransform, type PanInfo } from 'framer-motion';

/* ─── Card Data ────────────────────────────────────────────── */

export interface CardData {
  id: string;
  gradient: string;
  chipColor: string;
  textColor?: string;
  brandColor?: string;
  number: string;
  holder: string;
  expiry: string;
}

export const cardsData: CardData[] = [
  {
    id: 'visa-black',
    gradient: 'bg-gradient-to-br from-slate-900 via-purple-950 to-slate-900',
    chipColor: 'from-amber-200 via-yellow-300 to-amber-100',
    number: '4000 1234 5678 4242',
    holder: 'ALEX JORDAN',
    expiry: '08/28',
  },
  {
    id: 'visa-platinum',
    gradient: 'bg-gradient-to-br from-indigo-900 via-slate-800 to-zinc-900',
    chipColor: 'from-amber-200 via-yellow-300 to-amber-100',
    brandColor: 'text-indigo-300',
    number: '4111 1111 1111 1111',
    holder: 'SAMIRA CHEN',
    expiry: '11/27',
  },
  {
    id: 'visa-gold',
    gradient: 'bg-gradient-to-br from-amber-700 via-yellow-600 to-amber-800',
    chipColor: 'from-yellow-100 via-amber-50 to-yellow-200',
    brandColor: 'text-yellow-900',
    number: '4555 7890 1234 5678',
    holder: 'MARCUS LEE',
    expiry: '03/29',
  },
  {
    id: 'visa-signature',
    gradient: 'bg-gradient-to-br from-neutral-900 via-stone-800 to-neutral-900',
    chipColor: 'from-amber-200 via-yellow-300 to-amber-100',
    number: '4980 0000 0000 0001',
    holder: 'PRIYA PATEL',
    expiry: '06/30',
  },
];

/* ─── Helpers ──────────────────────────────────────────────── */

function formatCardNumber(n: string): string {
  const digits = n.replace(/\D/g, '');
  const last4 = digits.slice(-4);
  return `•••• •••• •••• ${last4}`;
}

/* ─── CreditCard Component ─────────────────────────────────── */

interface CreditCardProps {
  card: CardData;
  style?: React.CSSProperties;
  className?: string;
}

export function CreditCard({ card, style, className = '' }: CreditCardProps) {
  const { gradient, chipColor, textColor = 'text-white', brandColor = 'text-white/90', number, holder, expiry } = card;

  return (
    <div
      className={`relative aspect-[1.586/1] w-full max-w-[400px] rounded-2xl ${gradient} p-6 shadow-2xl backdrop-blur-sm select-none ${className}`}
      style={{
        boxShadow: '0 20px 60px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.08)',
        ...style,
      }}
    >
      <div className="pointer-events-none absolute inset-[1px] rounded-[15px] border border-white/10" />

      <div className="flex items-center gap-3">
        <div
          className={`h-10 w-14 rounded-md bg-gradient-to-br ${chipColor} shadow-inner relative overflow-hidden`}
        >
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="h-full w-full rounded-sm border border-yellow-700/20" />
          </div>
          <div className="absolute left-1.5 top-1/2 -translate-y-1/2 flex flex-col gap-0.5">
            <div className="h-1 w-2 rounded bg-yellow-700/30" />
            <div className="h-1 w-2 rounded bg-yellow-700/30" />
          </div>
          <div className="absolute right-2 top-1/2 -translate-y-1/2 flex flex-col gap-0.5">
            <div className="h-1 w-1.5 rounded bg-yellow-700/30" />
            <div className="h-1 w-1.5 rounded bg-yellow-700/30" />
          </div>
        </div>

        <svg viewBox="0 0 24 24" className="h-6 w-6 text-white/60" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
          <path d="M5 16a6 6 0 0 1 14 0" />
          <path d="M7 13a4 4 0 0 1 10 0" />
          <path d="M9 10a2 2 0 0 1 6 0" />
        </svg>
      </div>

      <p className={`mt-6 text-center text-xl tracking-[6px] ${textColor} font-mono font-medium`}>
        {formatCardNumber(number)}
      </p>

      <div className="mt-4 flex items-end justify-between">
        <div className="space-y-0.5">
          <p className={`text-[10px] tracking-widest ${textColor} opacity-50`}>CARD HOLDER</p>
          <p className={`text-sm tracking-wider ${textColor} font-semibold`}>{holder}</p>
        </div>
        <div className="space-y-0.5 text-right">
          <p className={`text-[10px] tracking-widest ${textColor} opacity-50`}>EXPIRES</p>
          <p className={`text-sm tracking-wider ${textColor} font-semibold`}>{expiry}</p>
        </div>
      </div>

      <div className={`absolute bottom-5 right-6 text-2xl font-black tracking-[-1px] ${brandColor}`}>VISA</div>
    </div>
  );
}

/* ─── CardRotate (drag wrapper) ────────────────────────────── */

interface CardRotateProps {
  children: ReactNode;
  onSendToBack: () => void;
  sensitivity: number;
}

function CardRotate({ children, onSendToBack, sensitivity }: CardRotateProps) {
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const rotateX = useTransform(y, [-100, 100], [60, -60]);
  const rotateY = useTransform(x, [-100, 100], [-60, 60]);

  const handleDragEnd = (_: MouseEvent | TouchEvent | PointerEvent, info: PanInfo) => {
    if (Math.abs(info.offset.x) > sensitivity || Math.abs(info.offset.y) > sensitivity) {
      onSendToBack();
    } else {
      x.set(0);
      y.set(0);
    }
  };

  return (
    <motion.div
      className="absolute inset-0"
      style={{ x, y, rotateX, rotateY, perspective: 1200 }}
      drag
      dragConstraints={{ top: 0, right: 0, bottom: 0, left: 0 }}
      dragElastic={0.6}
      whileTap={{ cursor: 'grabbing' }}
      onDragEnd={handleDragEnd}
    >
      {children}
    </motion.div>
  );
}

/* ─── Stack Container (React Bits API) ─────────────────────── */

interface StackProps {
  randomRotation?: boolean;
  sensitivity?: number;
  sendToBackOnClick?: boolean;
  cards?: ReactNode[];
  animationConfig?: { stiffness: number; damping: number };
  autoplay?: boolean;
  autoplayDelay?: number;
  pauseOnHover?: boolean;
}

export default function Stack({
  randomRotation = false,
  sensitivity = 200,
  cards = [],
  animationConfig = { stiffness: 260, damping: 20 },
  sendToBackOnClick = false,
  autoplay = false,
  autoplayDelay = 3000,
  pauseOnHover = false,
}: StackProps) {
  const [stack, setStack] = useState<{ id: number; content: ReactNode }[]>(() =>
    cards.map((content, i) => ({ id: i + 1, content })),
  );
  const [paused, setPaused] = useState(false);

  useEffect(() => {
    setStack(cards.map((content, i) => ({ id: i + 1, content })));
  }, [cards]);

  const sendToBack = useCallback((id: number) => {
    setStack((prev) => {
      const idx = prev.findIndex((c) => c.id === id);
      if (idx < 0) return prev;
      const next = [...prev];
      const [card] = next.splice(idx, 1);
      next.unshift(card);
      return next;
    });
  }, []);

  useEffect(() => {
    if (!autoplay || stack.length < 2 || paused) return;
    const interval = setInterval(() => {
      const topId = stack[stack.length - 1]?.id;
      if (topId != null) sendToBack(topId);
    }, autoplayDelay);
    return () => clearInterval(interval);
  }, [autoplay, autoplayDelay, stack, paused, sendToBack]);

  return (
    <div
      className="relative h-full w-full"
      onMouseEnter={() => pauseOnHover && setPaused(true)}
      onMouseLeave={() => pauseOnHover && setPaused(false)}
    >
      {stack.map((card, index) => {
        const rot = randomRotation ? Math.random() * 10 - 5 : 0;
        return (
          <CardRotate
            key={card.id}
            onSendToBack={() => sendToBack(card.id)}
            sensitivity={sensitivity}
          >
            <motion.div
              className="absolute inset-0 cursor-grab"
              onClick={() => sendToBackOnClick && sendToBack(card.id)}
              animate={{
                rotateZ: (stack.length - index - 1) * 4 + rot,
                scale: 1 + index * 0.06 - stack.length * 0.06,
              }}
              initial={false}
              transition={{ type: 'spring', stiffness: animationConfig.stiffness, damping: animationConfig.damping }}
              style={{ zIndex: index, transformOrigin: '90% 90%' }}
            >
              {card.content}
            </motion.div>
          </CardRotate>
        );
      })}
    </div>
  );
}

/* ─── Demo ─────────────────────────────────────────────────── */

export function CreditCardStackDemo() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-indigo-950 via-slate-900 to-zinc-950 p-8">
      <div style={{ width: 360, height: 360 }}>
        <Stack
          randomRotation={false}
          sensitivity={200}
          sendToBackOnClick={true}
          cards={cardsData.map((card) => (
            <CreditCard key={card.id} card={card} />
          ))}
          autoplay={false}
          autoplayDelay={3000}
          pauseOnHover={false}
        />
      </div>
    </div>
  );
}
