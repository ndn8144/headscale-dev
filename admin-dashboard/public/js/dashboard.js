// Enhanced Dashboard JavaScript
// Modern Headscale Admin Dashboard

class DashboardManager {
    constructor() {
        this.socket = io();
        this.charts = {};
        this.stats = {
            totalNodes: 0,
            onlineNodes: 0,
            totalUsers: 0,
            totalPreauthKeys: 0
        };
        
        this.init();
    }
    
    init() {
        this.setupSocketHandlers();
        this.setupEventListeners();
        this.initializeCharts();
        this.startPeriodicUpdates();
    }
    
    setupSocketHandlers() {
        this.socket.on('connect', () => {
            console.log('🔗 Connected to server');
            this.showNotification('Connected to server', 'success');
        });
        
        this.socket.on('disconnect', () => {
            console.log('❌ Disconnected from server');
            this.showNotification('Disconnected from server', 'warning');
        });
        
        this.socket.on('stats_update', (newStats) => {
            this.updateStats(newStats);
        });
        
        this.socket.on('node_status_change', (nodeData) => {
            this.handleNodeStatusChange(nodeData);
        });
        
        this.socket.on('user_activity', (activityData) => {
            this.addActivityItem(activityData);
        });
    }
    
    setupEventListeners() {
        // Dark mode toggle
        const darkModeToggle = document.getElementById('darkModeToggle');
        if (darkModeToggle) {
            darkModeToggle.addEventListener('click', () => this.toggleDarkMode());
        }
        
        // Sidebar toggle for mobile
        const sidebarToggle = document.getElementById('sidebarToggle');
        if (sidebarToggle) {
            sidebarToggle.addEventListener('click', () => this.toggleSidebar());
        }
        
        // Refresh buttons
        document.querySelectorAll('[data-refresh]').forEach(btn => {
            btn.addEventListener('click', (e) => this.handleRefresh(e));
        });
        
        // Chart period selectors
        document.querySelectorAll('[data-period]').forEach(item => {
            item.addEventListener('click', (e) => this.handlePeriodChange(e));
        });
        
        // Quick action buttons
        document.querySelectorAll('[data-loading]').forEach(btn => {
            btn.addEventListener('click', (e) => this.handleLoadingButton(e));
        });
    }
    
    initializeCharts() {
        this.initNetworkActivityChart();
        this.initNodeStatusChart();
    }
    
    initNetworkActivityChart() {
        const ctx = document.getElementById('networkActivityChart');
        if (!ctx) return;
        
        const timeData = this.generateTimeData();
        
        this.charts.networkActivity = new Chart(ctx, {
            type: 'line',
            data: {
                labels: timeData.labels,
                datasets: [
                    {
                        label: 'Online Nodes',
                        data: timeData.data,
                        borderColor: 'rgb(99, 102, 241)',
                        backgroundColor: 'rgba(99, 102, 241, 0.1)',
                        tension: 0.4,
                        fill: true,
                        pointRadius: 3,
                        pointHoverRadius: 6
                    },
                    {
                        label: 'Connected Users',
                        data: timeData.data.map(d => Math.floor(d * 0.7)),
                        borderColor: 'rgb(16, 185, 129)',
                        backgroundColor: 'rgba(16, 185, 129, 0.1)',
                        tension: 0.4,
                        fill: true,
                        pointRadius: 3,
                        pointHoverRadius: 6
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: true,
                        position: 'top',
                        labels: {
                            usePointStyle: true,
                            padding: 20,
                            font: {
                                family: 'Inter'
                            }
                        }
                    },
                    tooltip: {
                        mode: 'index',
                        intersect: false,
                        backgroundColor: 'rgba(0, 0, 0, 0.8)',
                        titleColor: '#fff',
                        bodyColor: '#fff',
                        borderColor: 'rgba(99, 102, 241, 0.8)',
                        borderWidth: 1,
                        titleFont: {
                            family: 'Inter'
                        },
                        bodyFont: {
                            family: 'Inter'
                        }
                    }
                },
                scales: {
                    x: {
                        display: true,
                        grid: {
                            display: false
                        },
                        ticks: {
                            font: {
                                family: 'Inter'
                            }
                        }
                    },
                    y: {
                        beginAtZero: true,
                        grid: {
                            color: 'rgba(0, 0, 0, 0.05)'
                        },
                        ticks: {
                            font: {
                                family: 'Inter'
                            }
                        }
                    }
                },
                interaction: {
                    mode: 'nearest',
                    axis: 'x',
                    intersect: false
                }
            }
        });
    }
    
    initNodeStatusChart() {
        const ctx = document.getElementById('nodeStatusChart');
        if (!ctx) return;
        
        this.charts.nodeStatus = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Online', 'Offline', 'Pending'],
                datasets: [{
                    data: [this.stats.onlineNodes || 5, (this.stats.totalNodes - this.stats.onlineNodes) || 2, 1],
                    backgroundColor: [
                        'rgb(16, 185, 129)',
                        'rgb(239, 68, 68)',
                        'rgb(245, 158, 11)'
                    ],
                    borderWidth: 0,
                    cutout: '70%'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        backgroundColor: 'rgba(0, 0, 0, 0.8)',
                        titleColor: '#fff',
                        bodyColor: '#fff',
                        titleFont: {
                            family: 'Inter'
                        },
                        bodyFont: {
                            family: 'Inter'
                        }
                    }
                }
            }
        });
    }
    
    generateTimeData() {
        const now = new Date();
        const data = [];
        const labels = [];
        
        for (let i = 23; i >= 0; i--) {
            const time = new Date(now.getTime() - i * 60 * 60 * 1000);
            labels.push(time.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }));
            data.push(Math.floor(Math.random() * 10) + (this.stats.onlineNodes - 5));
        }
        
        return { labels, data };
    }
    
    updateStats(newStats) {
        this.stats = { ...this.stats, ...newStats };
        
        // Update stat cards with animation
        this.updateStatCard(0, newStats.totalNodes);
        this.updateStatCard(1, newStats.onlineNodes);
        this.updateStatCard(2, newStats.totalUsers);
        this.updateStatCard(3, newStats.totalPreauthKeys);
        
        // Update charts
        this.updateCharts(newStats);
    }
    
    updateStatCard(index, newValue) {
        const statElements = document.querySelectorAll('.stats-number');
        if (statElements[index]) {
            const currentValue = parseInt(statElements[index].textContent) || 0;
            if (currentValue !== newValue) {
                this.animateCounter(statElements[index], currentValue, newValue, 1000);
            }
        }
    }
    
    animateCounter(element, start, end, duration) {
        const startTime = performance.now();
        const difference = end - start;
        
        const updateCounter = (currentTime) => {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            const currentValue = Math.floor(start + (difference * this.easeOutQuart(progress)));
            element.textContent = currentValue;
            
            if (progress < 1) {
                requestAnimationFrame(updateCounter);
            }
        };
        
        requestAnimationFrame(updateCounter);
    }
    
    easeOutQuart(t) {
        return 1 - Math.pow(1 - t, 4);
    }
    
    updateCharts(newStats) {
        // Update network activity chart
        if (this.charts.networkActivity) {
            const chart = this.charts.networkActivity;
            chart.data.datasets[0].data.shift();
            chart.data.datasets[0].data.push(newStats.onlineNodes);
            chart.data.datasets[1].data.shift();
            chart.data.datasets[1].data.push(Math.floor(newStats.onlineNodes * 0.7));
            
            chart.data.labels.shift();
            chart.data.labels.push(new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }));
            
            chart.update('none');
        }
        
        // Update node status chart
        if (this.charts.nodeStatus) {
            this.charts.nodeStatus.data.datasets[0].data = [
                newStats.onlineNodes,
                newStats.totalNodes - newStats.onlineNodes,
                Math.floor(Math.random() * 3)
            ];
            this.charts.nodeStatus.update('none');
        }
    }
    
    toggleDarkMode() {
        const body = document.body;
        const currentTheme = body.getAttribute('data-theme');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        
        body.setAttribute('data-theme', newTheme);
        localStorage.setItem('theme', newTheme);
        
        this.updateDarkModeIcon(newTheme);
        this.updateChartsTheme(newTheme);
    }
    
    updateDarkModeIcon(theme) {
        const icon = document.querySelector('#darkModeToggle i');
        if (icon) {
            if (theme === 'dark') {
                icon.className = 'fas fa-sun';
                document.getElementById('darkModeToggle').title = 'Switch to light mode';
            } else {
                icon.className = 'fas fa-moon';
                document.getElementById('darkModeToggle').title = 'Switch to dark mode';
            }
        }
    }
    
    updateChartsTheme(theme) {
        Object.values(this.charts).forEach(chart => {
            if (chart && chart.options && chart.options.scales) {
                const gridColor = theme === 'dark' ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)';
                if (chart.options.scales.y && chart.options.scales.y.grid) {
                    chart.options.scales.y.grid.color = gridColor;
                }
                chart.update('none');
            }
        });
    }
    
    toggleSidebar() {
        const sidebar = document.getElementById('sidebar');
        const overlay = document.querySelector('.sidebar-overlay');
        
        if (sidebar && overlay) {
            sidebar.classList.toggle('show');
            overlay.classList.toggle('show');
        }
    }
    
    handleRefresh(e) {
        const button = e.currentTarget;
        const icon = button.querySelector('i');
        
        if (icon) {
            icon.classList.add('refreshing');
            
            // Simulate refresh
            setTimeout(() => {
                icon.classList.remove('refreshing');
                this.addActivityItem({
                    type: 'system',
                    title: 'Dashboard refreshed',
                    description: 'Latest data synchronized',
                    time: 'Just now',
                    icon: 'fas fa-sync-alt',
                    color: 'info'
                });
            }, 1000);
        }
    }
    
    handlePeriodChange(e) {
        e.preventDefault();
        
        // Update active state
        document.querySelectorAll('.dropdown-item').forEach(item => {
            item.classList.remove('active');
        });
        e.currentTarget.classList.add('active');
        
        // Update button text
        const button = e.currentTarget.closest('.dropdown').querySelector('.dropdown-toggle');
        button.textContent = e.currentTarget.textContent;
        
        // Update chart data
        const period = e.currentTarget.getAttribute('data-period');
        this.updateChartPeriod(period);
    }
    
    updateChartPeriod(period) {
        if (!this.charts.networkActivity) return;
        
        let newLabels, newData;
        
        switch(period) {
            case '1h':
                newLabels = Array.from({length: 12}, (_, i) => {
                    const time = new Date(Date.now() - (11 - i) * 5 * 60 * 1000);
                    return time.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
                });
                break;
            case '7d':
                newLabels = Array.from({length: 7}, (_, i) => {
                    const date = new Date(Date.now() - (6 - i) * 24 * 60 * 60 * 1000);
                    return date.toLocaleDateString('en-US', { weekday: 'short' });
                });
                break;
            case '30d':
                newLabels = Array.from({length: 30}, (_, i) => {
                    const date = new Date(Date.now() - (29 - i) * 24 * 60 * 60 * 1000);
                    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
                });
                break;
            default: // 24h
                newLabels = this.generateTimeData().labels;
        }
        
        newData = newLabels.map(() => Math.floor(Math.random() * 10) + (this.stats.onlineNodes - 5));
        
        this.charts.networkActivity.data.labels = newLabels;
        this.charts.networkActivity.data.datasets[0].data = newData;
        this.charts.networkActivity.data.datasets[1].data = newData.map(d => Math.floor(d * 0.7));
        this.charts.networkActivity.update();
    }
    
    handleLoadingButton(e) {
        const button = e.currentTarget;
        const originalContent = button.innerHTML;
        
        button.innerHTML = '<span class="loading me-2"></span>Loading...';
        button.disabled = true;
        
        setTimeout(() => {
            button.innerHTML = originalContent;
            button.disabled = false;
        }, 2000);
    }
    
    addActivityItem(activityData) {
        const activityFeed = document.getElementById('activityFeed');
        if (!activityFeed) return;
        
        const newActivity = document.createElement('div');
        newActivity.className = 'activity-item';
        newActivity.innerHTML = `
            <div class="activity-icon bg-${activityData.color || 'primary'}">
                <i class="${activityData.icon || 'fas fa-info'}"></i>
            </div>
            <div class="activity-content">
                <div class="activity-title">${activityData.title}</div>
                <div class="activity-desc">${activityData.description}</div>
                <div class="activity-time">${activityData.time}</div>
            </div>
        `;
        
        activityFeed.insertBefore(newActivity, activityFeed.firstChild);
        
        // Animate in
        newActivity.style.opacity = '0';
        newActivity.style.transform = 'translateX(-20px)';
        
        setTimeout(() => {
            newActivity.style.opacity = '1';
            newActivity.style.transform = 'translateX(0)';
        }, 100);
        
        // Remove excess items
        if (activityFeed.children.length > 6) {
            activityFeed.removeChild(activityFeed.lastChild);
        }
    }
    
    handleNodeStatusChange(nodeData) {
        const message = nodeData.status === 'online' 
            ? `Node "${nodeData.name}" came online`
            : `Node "${nodeData.name}" went offline`;
            
        this.addActivityItem({
            type: 'node',
            title: nodeData.status === 'online' ? 'Node Connected' : 'Node Disconnected',
            description: message,
            time: 'Just now',
            icon: 'fas fa-server',
            color: nodeData.status === 'online' ? 'success' : 'danger'
        });
    }
    
    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `alert alert-${type} alert-dismissible fade show position-fixed`;
        notification.style.cssText = 'top: 20px; right: 20px; z-index: 9999; max-width: 350px;';
        notification.innerHTML = `
            <i class="fas fa-${this.getNotificationIcon(type)} me-2"></i>
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        
        document.body.appendChild(notification);
        
        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                const bsAlert = new bootstrap.Alert(notification);
                if (bsAlert) bsAlert.close();
            }
        }, 5000);
    }
    
    getNotificationIcon(type) {
        const icons = {
            success: 'check-circle',
            warning: 'exclamation-triangle',
            danger: 'exclamation-circle',
            info: 'info-circle'
        };
        return icons[type] || 'info-circle';
    }
    
    startPeriodicUpdates() {
        // Update charts every 30 seconds
        setInterval(() => {
            this.updateCharts({
                onlineNodes: this.stats.onlineNodes + Math.floor(Math.random() * 3) - 1,
                totalNodes: this.stats.totalNodes,
                totalUsers: this.stats.totalUsers,
                totalPreauthKeys: this.stats.totalPreauthKeys
            });
        }, 30000);
        
        // Simulate random activities
        setInterval(() => {
            const activities = [
                { title: 'User authenticated', description: 'Successful login from new device', icon: 'fas fa-sign-in-alt', color: 'success' },
                { title: 'Key expired', description: 'Pre-auth key reached expiration', icon: 'fas fa-key', color: 'warning' },
                { title: 'Route updated', description: 'Network routing table modified', icon: 'fas fa-route', color: 'info' },
                { title: 'Health check', description: 'System health verification passed', icon: 'fas fa-heartbeat', color: 'success' }
            ];
            
            const randomActivity = activities[Math.floor(Math.random() * activities.length)];
            randomActivity.time = 'Just now';
            
            this.addActivityItem(randomActivity);
        }, 60000); // Every minute
    }
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.dashboardManager = new DashboardManager();
});

// Global refresh function for compatibility
function refreshActivity() {
    if (window.dashboardManager) {
        window.dashboardManager.handleRefresh({ currentTarget: { querySelector: () => ({ classList: { add: () => {}, remove: () => {} } }) } });
    }
}
