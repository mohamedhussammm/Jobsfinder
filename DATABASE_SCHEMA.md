# ShiftSphere - Database Schema Reference

## Overview

ShiftSphere uses Supabase (PostgreSQL) with 8 main tables and comprehensive Row-Level Security (RLS) policies.

## Tables

### 1. `users` - All user types

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255),
  role VARCHAR(50) CHECK (role IN ('normal', 'company', 'team_leader', 'admin')),
  phone VARCHAR(20),
  national_id_number VARCHAR(50) UNIQUE NOT NULL,
  avatar_path VARCHAR(500),
  profile_complete BOOLEAN DEFAULT FALSE,
  rating_avg NUMERIC(3,2) DEFAULT 0 CHECK (rating_avg BETWEEN 0 AND 5),
  rating_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP -- soft delete for blocking users
)
```

**Fields:**
- `id` - UUID, auto-generated
- `email` - Unique, matches Supabase Auth email
- `role` - One of: 'normal', 'company', 'team_leader', 'admin'
- `national_id_number` - Unique identifier for user
- `rating_avg` - Average rating from team leaders (0-5)
- `rating_count` - Total number of ratings received
- `deleted_at` - Set when user is blocked by admin

**Indexes:**
- `idx_users_role` - Query users by role
- `idx_users_email` - Email lookups
- `idx_users_national_id` - ID lookups

**RLS Enabled:** Yes

---

### 2. `companies` - Company profiles

```sql
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  logo_path VARCHAR(500),
  verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
)
```

**Fields:**
- `id` - UUID, auto-generated
- `name` - Company name
- `verified` - Set by admin after verification
- `logo_path` - URL to company logo in storage

**Indexes:**
- `idx_companies_name` - Search companies

**RLS Enabled:** Yes

---

### 3. `events` - Job/shift events

```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  location JSONB, -- {address: string, lat: double, lng: double}
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP NOT NULL,
  capacity INTEGER CHECK (capacity > 0),
  image_path VARCHAR(500),
  status VARCHAR(50) CHECK (
    status IN ('draft', 'pending', 'published', 'completed', 'cancelled')
  ) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT valid_event_times CHECK (end_time > start_time)
)
```

**Status Workflow:**
- `draft` → `pending` → `published` → `completed`
- `pending` → `cancelled` (if rejected by admin)

**Fields:**
- `location` - JSONB with address, latitude, longitude
- `status` - Strict workflow, controls visibility
- `image_path` - Event image in storage

**Indexes:**
- `idx_events_status` - Filter by status (crucial for homepage)
- `idx_events_company_id` - Get company events
- `idx_events_start_time` - Sort by date

**RLS Enabled:** Yes

**Important:**
- Only `pending` and `published` events visible based on user role
- Companies can only INSERT with status='pending'
- Only admins can change status

---

### 4. `applications` - User applications to events

```sql
CREATE TABLE applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  status VARCHAR(50) CHECK (
    status IN ('applied', 'shortlisted', 'invited', 'accepted', 'declined', 'rejected')
  ) DEFAULT 'applied',
  cv_path VARCHAR(500),
  cover_letter TEXT,
  applied_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE (user_id, event_id) -- One application per user per event
)
```

**Status Progression:**
- `applied` → `shortlisted` → `invited` → `accepted/declined/rejected`

**Fields:**
- `cv_path` - Path to CV in Supabase Storage (signed URL)
- `cover_letter` - Optional cover letter text
- `status` - Team leader manages progression

**Indexes:**
- `idx_applications_event_id` - Get all applicants for event
- `idx_applications_user_id` - Get user applications
- `idx_applications_status` - Filter by status

**RLS Enabled:** Yes

**Constraints:**
- Users can apply only once per event
- Team leaders can only update applications for assigned events

---

### 5. `team_leaders` - Admin assignments

```sql
CREATE TABLE team_leaders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  assigned_by UUID REFERENCES users(id) ON DELETE SET NULL,
  status VARCHAR(50) CHECK (
    status IN ('assigned', 'active', 'completed', 'removed')
  ) DEFAULT 'assigned',
  assigned_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE (user_id, event_id) -- One assignment per leader per event
)
```

**Fields:**
- `user_id` - Team leader user
- `assigned_by` - Admin who assigned them
- `status` - Lifecycle of assignment

**Indexes:**
- `idx_team_leaders_event_id` - Get leaders for event
- `idx_team_leaders_user_id` - Get events for leader
- `idx_team_leaders_status` - Filter by status

**RLS Enabled:** Yes

---

### 6. `ratings` - Applicant ratings

```sql
CREATE TABLE ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rater_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rated_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id UUID REFERENCES events(id) ON DELETE SET NULL,
  score SMALLINT NOT NULL CHECK (score BETWEEN 1 AND 5),
  text_review TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE (rater_user_id, rated_user_id, event_id),
  CONSTRAINT no_self_rating CHECK (rater_user_id != rated_user_id)
)
```

**Fields:**
- `rater_user_id` - Team leader giving rating
- `rated_user_id` - Applicant being rated
- `score` - 1-5 rating
- `text_review` - Optional review text

**Indexes:**
- `idx_ratings_rated_user` - Get ratings for user
- `idx_ratings_event` - Get event ratings

**RLS Enabled:** Yes

**Important:**
- **IMMUTABLE** - cannot be updated/deleted after creation
- Auto-updates user's average rating in `users` table
- One rating per rater-user-event combination

---

### 7. `notifications` - Push notifications

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) CHECK (
    type IN ('invite', 'accepted', 'declined', 'message', 'rating', 'application_status')
  ) DEFAULT 'message',
  related_id UUID,
  title VARCHAR(255),
  message TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
)
```

**Fields:**
- `type` - Category of notification
- `related_id` - Links to event, application, etc.
- `is_read` - Marks as read by user

**Indexes:**
- `idx_notifications_user_id` - Get user notifications
- `idx_notifications_is_read` - Filter unread
- `idx_notifications_created_at` - Sort by date

**RLS Enabled:** Yes

---

### 8. `audit_logs` - Admin action tracking

```sql
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(255) NOT NULL,
  target_table VARCHAR(100),
  target_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address VARCHAR(45),
  created_at TIMESTAMP DEFAULT NOW()
)
```

**Fields:**
- `action` - What was done (e.g., 'event_approved', 'user_blocked')
- `target_table` - Which table was affected
- `target_id` - Which record
- `old_values/new_values` - JSONB snapshots before/after

**Indexes:**
- `idx_audit_logs_admin_user` - Get admin actions
- `idx_audit_logs_target` - Get changes to specific record
- `idx_audit_logs_created_at` - Timeline queries

**RLS Enabled:** Yes

**Tracked Actions:**
- Event approval/rejection
- Team leader assignment/removal
- User blocking/unblocking
- Application status changes
- Ratings submitted

---

## Relationships

```
users
  ├── 1:* → companies (company creator)
  ├── 1:* → events (event creator/company)
  ├── 1:* → applications (applicant)
  ├── 1:* → team_leaders (assigned leader)
  ├── 1:* → ratings (rater & rater-ee)
  └── 1:* → audit_logs (admin)

companies
  └── 1:* → events

events
  ├── 1:* → applications
  ├── 1:* → team_leaders
  └── 1:* → ratings

applications
  ├── 1:* → ratings
  └── n:n ↔ team_leaders (via event)

team_leaders
  └── 1:* → ratings (assignment scope)
```

---

## Common Queries

### Homepage - Get published events
```sql
SELECT * FROM events
WHERE status = 'published'
ORDER BY start_time ASC
LIMIT 10 OFFSET 0
```

### Get pending approvals
```sql
SELECT * FROM events
WHERE status = 'pending'
ORDER BY created_at ASC
```

### Get user applications
```sql
SELECT * FROM applications
WHERE user_id = '<user_id>'
ORDER BY applied_at DESC
```

### Get event applicants
```sql
SELECT a.*, u.name, u.rating_avg
FROM applications a
JOIN users u ON a.user_id = u.id
WHERE a.event_id = '<event_id>'
ORDER BY a.applied_at DESC
```

### Get team leader events
```sql
SELECT DISTINCT e.*
FROM events e
JOIN team_leaders tl ON e.id = tl.event_id
WHERE tl.user_id = '<team_leader_id>'
AND tl.status != 'removed'
```

### Get user ratings
```sql
SELECT * FROM ratings
WHERE rated_user_id = '<user_id>'
ORDER BY created_at DESC
```

### Update user average rating
```sql
UPDATE users
SET rating_avg = (
  SELECT AVG(score) FROM ratings WHERE rated_user_id = '<user_id>'
),
rating_count = (
  SELECT COUNT(*) FROM ratings WHERE rated_user_id = '<user_id>'
)
WHERE id = '<user_id>'
```

---

## Performance Tips

1. **Use indexes** - All high-frequency queries have indexes
2. **Pagination** - Always limit results (10-20 items)
3. **Filter by status** - Use `status` index for events/applications
4. **Denormalize carefully** - `rating_avg` and `rating_count` in `users` for quick access
5. **Archive old data** - Consider archiving events > 1 year old

---

## Triggers

### Auto-update `updated_at`
```sql
CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
```

Applied to: users, companies, events, team_leaders, applications

---

## RLS Policies

All tables have RLS enabled with policies:

- **Users**: Can read own data + public profile (name, avatar), admins can read all
- **Companies**: Can read verified companies, creators can manage own
- **Events**: Published visible to all, pending only to company & admin, draft only to company
- **Applications**: Users see own, team leaders see event applications
- **Team Leaders**: Only assignees and admins can view
- **Ratings**: Rater/ratee can view, team leads can view related applications
- **Notifications**: Users see only own notifications
- **Audit Logs**: Admins only

---

**Schema Version: 1.0**  
**Last Updated: 2025**
