/* =============================================
   Recycle Ekhaya — dashboard.js
   Role: Frontend ↔ Backend Contract Layer
   ============================================= */

'use strict';

/* =============================================
   API CONTRACT (FOR BACKEND TEAM)

   All endpoints must return JSON.

   GET /api/auth/me
   -> { first_name, last_name, city, country }

   GET /api/dashboard/stats
   -> {
        wallet_balance,        // number: current wallet balance in currency units
        wallet_change_week,    // number: percentage change in wallet balance over the past week
        total_recycled_kg,     // total kilograms recycled by user
        recycled_change_pct,   // percentage change in recycled kg over the past month
        pickups_completed,     // total number of completed pickups
        pickups_change_month,  // percentage change in pickups over the past month
        co2_saved_tons,        // total CO2 saved in tons
        co2_change_month       // percentage change in CO2 saved over the past month
      }
      // Note: percentage delta fields may be provided by backend for future UI enhancements.

   GET /api/pickups?limit=6
   -> [{ id, date, type, color, weight, status }]  // array of recent pickups, limited to 6

   GET /api/analytics/mix
   -> {
        materials: [{ name, pct }],  // array of material types with percentage composition
        this_month_kg,              // number: total kg recycled this month
        avg_per_pickup_kg           // number: average kg per pickup
      }

   GET /api/analytics/weekly
   -> {
        week: [{ day, kg }],  // array of daily kg recycled for the past week
        max_kg                // number: maximum kg in any day this week
      }

   GET /api/notifications/unread-count
   -> { unread }  // number: count of unread notifications

   GET /api/pickups/pending-count
   -> { count }   // number: count of pending pickups
============================================= */


/* =============================================
   API LAYER (Replace with real backend)
   ============================================= */

/**
 * Wrapper function for fetching JSON data from API endpoints.
 * Throws an error if the response is not ok (status >= 400).
 * Backend should ensure all endpoints return proper HTTP status codes.
 * NOTE: this app uses JEE session cookies, so fetch includes credentials.
 * @param {string} url - The API endpoint URL
 * @returns {Promise<Object>} - Parsed JSON response
 * @throws {Error} - If fetch fails or response is not ok
 */
async function apiFetch(url) {
  const res = await fetch(url, {
    credentials: 'include',
    headers: { 'Accept': 'application/json' }
  });
  if (!res.ok) throw new Error(`API error: ${url}`);
  return res.json();
}


/* =============================================
   UI MODULES
   ============================================= */

/* --- Sidebar --- */
function initSidebar() {
  const sidebar = document.getElementById('sidebar');
  const toggleBtn = document.getElementById('toggleBtn');

  if (!sidebar || !toggleBtn) return;

  toggleBtn.addEventListener('click', () => {
    sidebar.classList.toggle('collapsed');
    document.body.classList.toggle('sidebar-collapsed');

    // Persist state
    localStorage.setItem('sidebar', sidebar.classList.contains('collapsed'));
  });

  // Restore state
  if (localStorage.getItem('sidebar') === 'true') {
    sidebar.classList.add('collapsed');
    document.body.classList.add('sidebar-collapsed');
  }
}

/* --- Sign out --- */
function initSignOut() {
  const signOutBtn = document.getElementById('signOutBtn');
  if (signOutBtn) {
    signOutBtn.addEventListener('click', async () => {
      await fetch('/api/auth/logout', { method: 'POST' });
      window.location.href = '/login.jsp';
    });
  }
}

/* --- Header --- */
/**
 * Initializes the dashboard header with user information and greeting.
 * Backend should provide user data via GET /api/auth/me
 * @param {Object} user - User object from backend
 * @param {string} user.first_name - User's first name
 * @param {string} user.last_name - User's last name
 * @param {string} user.city - User's city
 * @param {string} user.country - User's country
 */
function initHeader(user) {
  const hour = new Date().getHours();
  const period = hour < 12 ? 'morning' : hour < 18 ? 'afternoon' : 'evening';

  const greetingEl = document.getElementById('greetingTime');
  if (greetingEl) {
    greetingEl.textContent = period;
  }

  const userNameEl = document.getElementById('userFirstName');
  if (userNameEl) {
    userNameEl.textContent = user?.first_name || 'User';
  }

  const locationEl = document.getElementById('headerLocation');
  if (locationEl) {
    locationEl.textContent = user ? `${user.city || 'Unknown'}, ${user.country || 'Location'}` : 'Unknown Location';
  }

  const avatarEl = document.getElementById('userAvatar');
  if (avatarEl) {
    const first = user?.first_name?.[0] || 'U';
    const last = user?.last_name?.[0] || '';
    avatarEl.textContent = first + last;
  }

  const dateEl = document.getElementById('headerDate');
  if (dateEl) {
    dateEl.textContent = new Date().toLocaleDateString('en-ZA', {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });
  }
}

/* --- Notifications --- */
/**
 * Shows or hides the notification indicator dot based on unread count.
 * Backend should provide count via GET /api/notifications/unread-count
 * @param {number} count - Number of unread notifications
 */
function initNotifications(count) {
  const dot = document.getElementById('notifDot');
  if (!dot) return;
  if (count > 0) {
    dot.hidden = false;
  } else {
    dot.hidden = true;
  }
}

/* --- Pending badge --- */
/**
 * Shows or hides the pending pickups badge with count.
 * Backend should provide count via GET /api/pickups/pending-count
 * @param {number} count - Number of pending pickups
 */
function initPendingBadge(count) {
  const badge = document.getElementById('pendingPickupsBadge');
  if (!badge) return;
  if (count > 0) {
    badge.textContent = count;
    badge.hidden = false;
  } else {
    badge.hidden = true;
  }
}

/* --- Stats --- */
/**
 * Populates the dashboard statistics cards with animated counting.
 * Backend should provide stats via GET /api/dashboard/stats
 * @param {Object} stats - Statistics object from backend
 * @param {number} stats.wallet_balance - Current wallet balance
 * @param {number} stats.wallet_change_week - Weekly change percentage
 * @param {number} stats.total_recycled_kg - Total recycled kg
 * @param {number} stats.recycled_change_pct - Monthly recycled change %
 * @param {number} stats.pickups_completed - Total completed pickups
 * @param {number} stats.pickups_change_month - Monthly pickups change %
 * @param {number} stats.co2_saved_tons - Total CO2 saved in tons
 * @param {number} stats.co2_change_month - Monthly CO2 change %
 */
function populateStats(stats) {
  function countUp(el, target, format) {
    if (!el) return; // Safety check: don't countUp if element doesn't exist
    const start = performance.now();
    const duration = 1200;

    (function tick(now) {
      const progress = Math.min((now - start) / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      el.textContent = format(Math.round(target * eased));
      if (progress < 1) requestAnimationFrame(tick);
    })(start);
  }

  const fmt = n => n.toLocaleString();

  const walletEl = document.getElementById('statWalletBalance');
  if (walletEl) {
    countUp(walletEl, stats?.wallet_balance || 0, n => `R ${fmt(n)}`);
  }

  const recycledEl = document.getElementById('statTotalRecycled');
  if (recycledEl) {
    countUp(recycledEl, stats?.total_recycled_kg || 0, n => `${fmt(n)} kg`);
  }

  const pickupEl = document.getElementById('statPickups');
  if (pickupEl) {
    countUp(pickupEl, stats?.pickups_completed || 0, n => fmt(n));
  }

  const co2El = document.getElementById('statCO2');
  if (co2El) {
    countUp(co2El, stats?.co2_saved_tons || 0, n => `${n.toFixed(1)} tons`);
  }

}

/* --- Table --- */
/**
 * Populates the recent pickups table with data.
 * Backend should provide pickups array via GET /api/pickups?limit=6
 * @param {Array} pickups - Array of pickup objects
 * @param {number} pickups[].id - Pickup ID
 * @param {string} pickups[].date - Pickup date
 * @param {string} pickups[].type - Type of waste/material
 * @param {string} pickups[].color - Color indicator (possibly for UI)
 * @param {number} pickups[].weight - Weight in kg
 * @param {string} pickups[].status - Pickup status (e.g., "completed", "pending")
 */
function createCell(text, className = '') {
  const td = document.createElement('td');
  td.textContent = text;
  if (className) td.className = className;
  return td;
}

function createStatusBadge(status) {
  const td = document.createElement('td');
  const span = document.createElement('span');

  span.classList.add('badge');

  // Normalize status: lowercase and replace underscores with spaces
  const normalized = (status || 'unknown').toString().toLowerCase().replace(/_/g, ' ');

  switch (normalized) {
    case 'pending':
      span.classList.add('badge--pending');
      break;
    case 'in progress':
      span.classList.add('badge--progress');
      break;
    case 'completed':
      span.classList.add('badge--done');
      break;
    case 'cancelled':
      span.classList.add('badge--cancelled');
      break;
  }

  span.textContent = status || 'Unknown';
  td.appendChild(span);
  return td;
}

function populateTable(pickups) {
  const tbody = document.getElementById('pickupTableBody');
  tbody.innerHTML = '';

  if (!Array.isArray(pickups) || !pickups.length) {
    const tr = document.createElement('tr');
    const td = document.createElement('td');
    td.colSpan = 5;
    td.textContent = 'No pickup requests found';
    td.style.textAlign = 'center';
    tr.appendChild(td);
    tbody.appendChild(tr);
    return;
  }

  const fragment = document.createDocumentFragment();

  pickups.forEach(p => {
    const tr = document.createElement('tr');

    tr.append(
      createCell(`#${p?.id || 'N/A'}`, 'td-id'),
      createCell(p?.date || 'Unknown', 'td-date'),
      createCell(p?.type || 'Unknown', 'td-type'),
      createCell(`${p?.weight || 0} kg`, 'td-weight'),
      createStatusBadge(p?.status)
    );

    fragment.appendChild(tr);
  });

  tbody.appendChild(fragment);
}

/* --- Mix --- */
/**
 * Populates the material mix analytics section.
 * Backend should provide mix data via GET /api/analytics/mix
 * @param {Object} mix - Material mix analytics object
 * @param {Array} mix.materials - Array of material objects
 * @param {string} mix.materials[].name - Material name
 * @param {number} mix.materials[].pct - Percentage of total
 * @param {number} mix.this_month_kg - Total kg this month
 * @param {number} mix.avg_per_pickup_kg - Average kg per pickup
 */
function populateMix(mix) {
  if (!mix) return;

  const thisMonthEl = document.getElementById('chipThisMonth');
  if (thisMonthEl) {
    thisMonthEl.textContent = mix.this_month_kg || 0;
  }

  const avgPickupEl = document.getElementById('chipAvgPickup');
  if (avgPickupEl) {
    avgPickupEl.textContent = mix.avg_per_pickup_kg || 0;
  }

  // Populate materials breakdown
  const container = document.getElementById('analyticsMaterials');
  if (!container) return;

  container.innerHTML = '';

  if (!mix.materials || !Array.isArray(mix.materials) || mix.materials.length === 0) {
    const noDataDiv = document.createElement('div');
    noDataDiv.textContent = 'No data';
    noDataDiv.className = 'material-row';
    container.appendChild(noDataDiv);
    return;
  }

  mix.materials.forEach(material => {
    const materialDiv = document.createElement('div');
    materialDiv.className = 'material-row';
    materialDiv.textContent = `${material?.name || 'Unknown'} - ${material?.pct || 0}%`;
    container.appendChild(materialDiv);
  });
}

/* --- Chart --- */
/**
 * Populates the weekly recycling chart with bars.
 * Backend should provide weekly data via GET /api/analytics/weekly
 * @param {Object} weekly - Weekly analytics object
 * @param {Array} weekly.week - Array of daily data
 * @param {string} weekly.week[].day - Day of week (e.g., "Mon", "Tue")
 * @param {number} weekly.week[].kg - Kilograms recycled that day
 * @param {number} weekly.max_kg - Maximum kg in any day (for scaling)
 */
function populateChart(weekly) {
  const container = document.getElementById('miniChartContainer');
  if (!container) return;

  container.innerHTML = '';

  if (!weekly || !weekly.week) {
    return;
  }

  weekly.week.forEach(d => {
    const bar = document.createElement('div');
    bar.className = 'bar';

    if (weekly.max_kg === 0) {
      bar.style.height = '0%';
    } else {
      bar.style.height = `${(d.kg / weekly.max_kg) * 100}%`;
    }

    container.appendChild(bar);
  });
}


/* =============================================
   BOOTSTRAP (MAIN INTEGRATION POINT)
   ============================================= */

/**
 * Main initialization function that runs when the DOM is loaded.
 * This function orchestrates all API calls to populate the dashboard.
 * Each API response is assigned to named variables and passed directly to UI functions.
 * Null checks protect against missing DOM elements and failed API calls.
 * Failed endpoints are logged with clear visibility.
 */
document.addEventListener('DOMContentLoaded', async () => {
  initSidebar();
  initSignOut();

  try {
    // Execute all API requests in parallel to avoid blocking page rendering.
    // This is safer for JEE backend integration: one failed endpoint will not stop the others.
    const [authRes, notifRes, pendingRes, statsRes, pickupsRes, mixRes, weeklyRes] = await Promise.allSettled([
      apiFetch('/api/auth/me'),
      apiFetch('/api/notifications/unread-count'),
      apiFetch('/api/pickups/pending-count'),
      apiFetch('/api/dashboard/stats'),
      apiFetch('/api/pickups?limit=6'),
      apiFetch('/api/analytics/mix'),
      apiFetch('/api/analytics/weekly')
    ]);

    // Safely extract values from Promise.allSettled results
    // Log failures per endpoint for visibility
    const authData = authRes.status === 'fulfilled' ? authRes.value : (console.warn('API FAILURE: /api/auth/me'), null);
    const notifData = notifRes.status === 'fulfilled' ? notifRes.value : (console.warn('API FAILURE: /api/notifications/unread-count'), null);
    const pendingData = pendingRes.status === 'fulfilled' ? pendingRes.value : (console.warn('API FAILURE: /api/pickups/pending-count'), null);
    const statsData = statsRes.status === 'fulfilled' ? statsRes.value : (console.warn('API FAILURE: /api/dashboard/stats'), null);
    const pickupsData = pickupsRes.status === 'fulfilled' ? pickupsRes.value : (console.warn('API FAILURE: /api/pickups?limit=6'), null);
    const mixData = mixRes.status === 'fulfilled' ? mixRes.value : (console.warn('API FAILURE: /api/analytics/mix'), null);
    const weeklyData = weeklyRes.status === 'fulfilled' ? weeklyRes.value : (console.warn('API FAILURE: /api/analytics/weekly'), null);

    // Call UI functions with explicit data binding and DOM element guards
    const headerEl = document.getElementById('greetingTime');
    if (headerEl) {
      const defaultUser = { first_name: "User", last_name: "", city: "", country: "" };
      initHeader(authData || defaultUser);
    }

    const notifEl = document.getElementById('notifDot');
    if (notifEl) {
      initNotifications(notifData?.unread || 0);
    }

    const pendingEl = document.getElementById('pendingPickupsBadge');
    if (pendingEl) {
      initPendingBadge(pendingData?.count || 0);
    }

    const statsEl = document.getElementById('statWalletBalance');
    if (statsEl) {
      populateStats(statsData || {});
    }

    const tableEl = document.getElementById('pickupTableBody');
    if (tableEl) {
      populateTable(pickupsData || []);
    }

    const mixEl = document.getElementById('analyticsMaterials');
    if (mixEl) {
      populateMix(mixData || {});
    }

    const chartEl = document.getElementById('miniChartContainer');
    if (chartEl) {
      populateChart(weeklyData || {});
    }

  } catch (err) {
    console.error('Dashboard critical failure:', err);
  }
});



  (function() {
    // ============================================
    // WALLET DATA - Replace with your actual API data
    // ============================================
    const walletData = {
      wallet_id: "(Insert wallet id here)",
      user_id: "(insert user id here)",
      balance: 1247.50, //where the amount stays
      currency: "USD",
      //credit = inserting money
    //debit = taking out money
      recentTransactions: [
        { date: "2026-05-05", description: "Recycling pickup reward", amount: "+25.00", type: "credit" },
        { date: "2026-05-03", description: "Referral bonus", amount: "+10.00", type: "credit" },
        { date: "2026-04-28", description: "Cash withdrawal", amount: "-50.00", type: "debit" },
        { date: "2026-04-25", description: "E-waste collection", amount: "+15.00", type: "credit" }
      ]
    };

    //credit = inserting money
    //debit = taking out money

    // Helper: Format currency
    function formatMoney(amount, currency = "ZAR") {
      return new Intl.NumberFormat('en-ZA', {
        style: 'currency',
        currency: 'ZAR',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(amount);
    }

    // Helper: Format date for display
    function formatDate(dateString) {
      const date = new Date(dateString);
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }

    // Render wallet data to DOM
    function renderWallet() {
      // Update balance display (main money amount)
      const balanceElement = document.getElementById('walletBalanceDisplay');
      if (balanceElement) {
        balanceElement.textContent = formatMoney(walletData.balance, walletData.currency);
      }

      // Update Wallet ID
      const walletIdText = document.getElementById('walletIdText');
      if (walletIdText) {
        walletIdText.textContent = walletData.wallet_id;
      }

      // Update User ID
      const userIdText = document.getElementById('userIdText');
      if (userIdText) {
        userIdText.textContent = walletData.user_id;
      }

      // Render recent transactions
      const transactionsList = document.getElementById('transactionsList');
      if (transactionsList && walletData.recentTransactions && walletData.recentTransactions.length) {
        transactionsList.innerHTML = walletData.recentTransactions.map(tx => `
          <div class="transaction-item ${tx.type}">
            <div class="transaction-info">
              <span class="transaction-desc">${escapeHtml(tx.description)}</span>
              <span class="transaction-date">${formatDate(tx.date)}</span>
            </div>
            <span class="transaction-amount ${tx.type === 'credit' ? 'positive' : 'negative'}">
              ${tx.type === 'credit' ? '+' : ''}${formatMoney(parseFloat(tx.amount), walletData.currency)}
            </span>
          </div>
        `).join('');
      } else if (transactionsList) {
        transactionsList.innerHTML = '<div class="transaction-placeholder">No recent transactions found.</div>';
      }
    }

    // Simple escape to prevent XSS
    function escapeHtml(str) {
      if (!str) return '';
      return str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
    }

    // Initialize wallet when DOM is ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => {
        renderWallet();
      });
    } else {
      renderWallet();
    }
  })();