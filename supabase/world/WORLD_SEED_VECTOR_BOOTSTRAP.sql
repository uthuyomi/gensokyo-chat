-- World seed: vector-ready bootstrap
-- Builds embedding documents from the loaded world_* canon and queues jobs.

select public.world_refresh_embedding_documents('gensokyo_main');

select public.world_queue_embedding_refresh('gensokyo_main');
