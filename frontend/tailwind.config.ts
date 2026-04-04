import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        background: '#1B1004',
        surface: '#241805',
        panel: '#2E1F08',
        primary: '#91621D',
        'primary-foreground': '#FEFAF6',
        text: '#FEFAF6',
        'text-muted': '#D1C1A7',
        border: '#4E3A16',
        accent: '#3A280B',
        success: '#4E7A51',
        warning: '#A97A20',
        danger: '#A04535',
        info: '#42698F',
      },
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        glow: '0 0 20px rgba(145,98,29,0.2)',
        card: '0 4px 24px rgba(0,0,0,0.35)',
        'card-hover': '0 8px 32px rgba(145,98,29,0.15)',
      },
      borderRadius: {
        '2xl': '1rem',
        '3xl': '1.25rem',
      },
      animation: {
        'fade-in': 'fadeIn 0.4s ease-out',
        'slide-up': 'slideUp 0.4s ease-out',
        'pulse-glow': 'pulseGlow 2s ease-in-out infinite',
      },
      keyframes: {
        fadeIn: {
          from: { opacity: '0' },
          to: { opacity: '1' },
        },
        slideUp: {
          from: { opacity: '0', transform: 'translateY(12px)' },
          to: { opacity: '1', transform: 'translateY(0)' },
        },
        pulseGlow: {
          '0%, 100%': { boxShadow: '0 0 8px rgba(145,98,29,0.15)' },
          '50%': { boxShadow: '0 0 20px rgba(145,98,29,0.35)' },
        },
      },
    },
  },
  plugins: [],
};

export default config;
