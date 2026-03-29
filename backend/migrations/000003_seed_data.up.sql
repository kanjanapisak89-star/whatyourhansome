-- =====================================================
-- Seed Data for Testing
-- =====================================================

-- Insert test users
INSERT INTO users (id, firebase_uid, email, display_name, avatar_url, provider, role, status) VALUES
('00000000-0000-0000-0000-000000000001', 'firebase_uid_1', 'marcus.thorne@example.com', 'Marcus Thorne', 'https://i.pravatar.cc/150?img=12', 'google', 'owner', 'active'),
('00000000-0000-0000-0000-000000000002', 'firebase_uid_2', 'sarah.chen@example.com', 'Sarah Chen', 'https://i.pravatar.cc/150?img=47', 'google', 'member', 'active'),
('00000000-0000-0000-0000-000000000003', 'firebase_uid_3', 'alex.rivera@example.com', 'Alex Rivera', 'https://i.pravatar.cc/150?img=33', 'facebook', 'member', 'active')
ON CONFLICT (firebase_uid) DO NOTHING;

-- Insert test posts (matching image_0.png design)
INSERT INTO posts (id, author_id, title, content, image_url, published, view_count, created_at) VALUES
(
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'The Obsidian Shift: Why physical borders are becoming digital posts.',
    'We are entering an era where the architecture of our reality, it''s no longer defined by the borders we define. It''s about the borders of our interfaces, the architecture of our reality.',
    'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800',
    true,
    1250,
    NOW() - INTERVAL '3 hours'
),
(
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000002',
    'The Silicon Oasis: Redefining sustainable luxury in the 2030s.',
    'Sustainability is moving beyond the environmental narrative. It''s about creating experiences that are both luxurious and responsible, where technology meets the environment while providing the ultimate lifestyle experience.',
    'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800',
    true,
    890,
    NOW() - INTERVAL '1 day'
),
(
    '10000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000001',
    'The Death of the Search Engine.',
    'We are at the front discovery to curation. Search engines are no longer about finding information, they''re about curating your reality. The shift from search to curation will redefine how we interact with the interface to the intuition.',
    'https://images.unsplash.com/photo-1488590528505-98d2b5aba04b?w=800',
    true,
    2100,
    NOW() - INTERVAL '3 hours'
)
ON CONFLICT (id) DO NOTHING;

-- Insert reactions (likes)
INSERT INTO reactions (user_id, post_id) VALUES
('00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002'),
('00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002'),
('00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002'),
('00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000003'),
('00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003')
ON CONFLICT (user_id, post_id) DO NOTHING;

-- Insert comments
INSERT INTO comments (post_id, user_id, content, created_at) VALUES
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'This is a fascinating perspective on digital transformation!', NOW() - INTERVAL '2 hours'),
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', 'I completely agree. The future is about interfaces, not physical spaces.', NOW() - INTERVAL '1 hour'),
('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Great insights on sustainable luxury. This is the future we need.', NOW() - INTERVAL '12 hours'),
('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000003', 'Love this vision! When can we see this in action?', NOW() - INTERVAL '10 hours'),
('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', 'The shift from search to curation is already happening. Look at TikTok!', NOW() - INTERVAL '2 hours')
ON CONFLICT DO NOTHING;

-- Insert board questions
INSERT INTO board_questions (user_id, title, content, status, created_at) VALUES
('00000000-0000-0000-0000-000000000002', 'How do I get started with digital transformation?', 'I''m interested in learning more about how to apply these concepts to my business. Where should I start?', 'pending', NOW() - INTERVAL '1 day'),
('00000000-0000-0000-0000-000000000003', 'What tools do you recommend for interface design?', 'I''m building a new product and want to focus on the interface-first approach. What tools and frameworks do you recommend?', 'answered', NOW() - INTERVAL '2 days')
ON CONFLICT DO NOTHING;

-- Update board question with answer
UPDATE board_questions
SET 
    admin_response = 'Great question! I recommend starting with Figma for design and React/Flutter for implementation. Focus on user experience first, then build the backend to support it.',
    status = 'answered',
    responded_by = '00000000-0000-0000-0000-000000000001',
    responded_at = NOW() - INTERVAL '1 day'
WHERE title = 'What tools do you recommend for interface design?';

-- Refresh materialized view
REFRESH MATERIALIZED VIEW post_stats;
