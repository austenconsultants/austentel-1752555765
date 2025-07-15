import React, { useState, useEffect } from 'react';
import { 
  Phone, Users, Settings, Activity, Shield, Database, 
  ChevronDown, Moon, Sun, Bell, Search, Menu, X,
  UserPlus, Upload, Download, RefreshCw, Filter,
  PhoneCall, PhoneMissed, PhoneIncoming, PhoneOutgoing,
  Zap, Server, Cpu, HardDrive, BarChart3, PieChart,
  Calendar, Clock, AlertTriangle, CheckCircle,
  Mic, MicOff, Volume2, VolumeX, Monitor,
  FileText, FileSpreadsheet, FileCode, Trash2, 
  CheckCircle2, AlertCircle, FileX, Edit, Save,
  Eye, EyeOff, Plus, Minus, Power, PowerOff
} from 'lucide-react';

const FreeSwitchUI = () => {
  const [darkMode, setDarkMode] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [activeTab, setActiveTab] = useState('dashboard');
  const [userRole, setUserRole] = useState('super-admin');
  const [currentTime, setCurrentTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <div className={`min-h-screen transition-colors duration-300 ${darkMode ? 'dark bg-gray-900' : 'bg-gray-50'}`}>
      <div className="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 sticky top-0 z-50">
        <div className="flex items-center justify-between px-6 h-16">
          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-red-600 rounded-lg flex items-center justify-center">
                <Zap className="w-5 h-5 text-white" />
              </div>
              <div className="flex items-center space-x-2">
                <h1 className="text-xl font-bold text-gray-900 dark:text-white">
                  AUSTEN<span className="text-red-600">TEL</span>
                </h1>
                <span className="text-sm text-gray-500 dark:text-gray-400">|</span>
                <span className="text-lg font-semibold text-gray-700 dark:text-gray-300">
                  ACS VoiceHub Pro
                </span>
              </div>
            </div>
          </div>
          
          <div className="flex items-center space-x-4">
            <div className="hidden md:flex items-center space-x-2 text-sm text-gray-600 dark:text-gray-400">
              <Clock className="w-4 h-4" />
              <span>{currentTime.toLocaleTimeString()}</span>
            </div>
            
            <button
              onClick={() => setDarkMode(!darkMode)}
              className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            >
              {darkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
            </button>
            
            <div className="w-10 h-10 bg-red-600 rounded-full flex items-center justify-center">
              <span className="text-white text-sm font-semibold">SA</span>
            </div>
          </div>
        </div>
      </div>

      <div className="p-6">
        <div className="mb-6">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
            ACS VoiceHub Pro Dashboard
          </h2>
          <p className="text-gray-600 dark:text-gray-400">
            FreeSWITCH Management Interface - Deployment Successful! 🚀
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700">
            <div className="flex items-center justify-between mb-4">
              <Phone className="w-8 h-8 text-red-600" />
              <span className="text-xs text-red-600 font-medium bg-red-50 px-2 py-1 rounded">Live</span>
            </div>
            <p className="text-3xl font-bold text-gray-900 dark:text-white mb-1">127</p>
            <p className="text-sm text-gray-600 dark:text-gray-400">Total Extensions</p>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700">
            <div className="flex items-center justify-between mb-4">
              <Activity className="w-8 h-8 text-green-600" />
              <span className="text-xs text-green-600 font-medium bg-green-50 px-2 py-1 rounded">Active</span>
            </div>
            <p className="text-3xl font-bold text-gray-900 dark:text-white mb-1">23</p>
            <p className="text-sm text-gray-600 dark:text-gray-400">Active Channels</p>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700">
            <div className="flex items-center justify-between mb-4">
              <PhoneCall className="w-8 h-8 text-blue-600" />
              <span className="text-xs text-blue-600 font-medium bg-blue-50 px-2 py-1 rounded">Today</span>
            </div>
            <p className="text-3xl font-bold text-gray-900 dark:text-white mb-1">1,847</p>
            <p className="text-sm text-gray-600 dark:text-gray-400">Calls Today</p>
          </div>

          <div className="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700">
            <div className="flex items-center justify-between mb-4">
              <Server className="w-8 h-8 text-purple-600" />
              <span className="text-xs text-green-600 font-medium bg-green-50 px-2 py-1 rounded">99.8%</span>
            </div>
            <p className="text-3xl font-bold text-gray-900 dark:text-white mb-1">Active</p>
            <p className="text-sm text-gray-600 dark:text-gray-400">System Status</p>
          </div>
        </div>

        <div className="mt-8 bg-gradient-to-br from-red-50 to-red-100 dark:from-red-900/20 dark:to-red-800/20 rounded-xl p-6">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
            🎉 Deployment Successful!
          </h3>
          <p className="text-gray-600 dark:text-gray-400">
            Your ACS VoiceHub Pro interface is now live and ready for FreeSWITCH integration.
            This is a fully functional React application with Tailwind CSS styling.
          </p>
        </div>
      </div>
    </div>
  );
};

export default FreeSwitchUI;
