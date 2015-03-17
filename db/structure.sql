CREATE TABLE `atom_errors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `standard_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `author_id` int(11) DEFAULT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `language` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `er_auth_idx` (`author_id`),
  CONSTRAINT `er_auth` FOREIGN KEY (`author_id`) REFERENCES `authors` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `author_urls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `author_id` int(11) DEFAULT NULL,
  `url` text COLLATE utf8_unicode_ci,
  `display_label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `url_auth_idx` (`author_id`),
  CONSTRAINT `url_auth` FOREIGN KEY (`author_id`) REFERENCES `authors` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=7877 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `authors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unique_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `phi_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tlg_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `stoa_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `alt_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `alt_parts` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `dates` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `alt_names` text COLLATE utf8_unicode_ci,
  `abbr` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `field_of_activity` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` text COLLATE utf8_unicode_ci,
  `related_works` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1886 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `bookmarks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `document_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `user_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `editors_or_translators` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `mads_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `alt_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `alt_parts` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `dates` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `alt_names` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `field_of_activity` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` text COLLATE utf8_unicode_ci,
  `urls` text COLLATE utf8_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=905 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `expression_urls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `exp_id` int(11) NOT NULL,
  `url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `display_label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `host_work` tinyint(1) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `eu_exp_idx` (`exp_id`),
  CONSTRAINT `eu_exp` FOREIGN KEY (`exp_id`) REFERENCES `expressions` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=51601 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `expressions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `work_id` int(11) NOT NULL,
  `tg_id` int(11) NOT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `alt_title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `abbr_title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `host_title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `editor_id` int(11) DEFAULT NULL,
  `translator_id` int(11) DEFAULT NULL,
  `language` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `place_publ` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `place_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `publisher` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `date_publ` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `date_mod` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `date_int` int(11) DEFAULT NULL,
  `edition` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phys_descr` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` text COLLATE utf8_unicode_ci,
  `subjects` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `table_of_cont` text COLLATE utf8_unicode_ci,
  `cts_urn` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `cts_label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `cts_descr` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `series_id` int(11) DEFAULT NULL,
  `pages` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `word_count` int(11) DEFAULT NULL,
  `oclc_id` int(11) DEFAULT NULL,
  `var_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `e_ed_idx` (`editor_id`),
  KEY `e_trans_idx` (`translator_id`),
  KEY `e_series_idx` (`series_id`),
  KEY `e_work_idx` (`work_id`),
  CONSTRAINT `e_ed` FOREIGN KEY (`editor_id`) REFERENCES `editors_or_translators` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `e_series` FOREIGN KEY (`series_id`) REFERENCES `series` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `e_trans` FOREIGN KEY (`translator_id`) REFERENCES `editors_or_translators` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `e_work` FOREIGN KEY (`work_id`) REFERENCES `works` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=10376 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `non_cataloged_expressions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cts_urn` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `work_id` int(11) NOT NULL,
  `cts_label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ed_trans` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `var_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `nce_w_idx` (`work_id`),
  CONSTRAINT `nce_tg` FOREIGN KEY (`work_id`) REFERENCES `works` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `non_cataloged_works` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `urn` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `textgroup_id` int(11) NOT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ed_trans` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `exp_edition` tinyint(1) DEFAULT NULL,
  `exp_translation` tinyint(1) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ncw_tg_idx` (`textgroup_id`),
  CONSTRAINT `ncw_tg` FOREIGN KEY (`textgroup_id`) REFERENCES `textgroups` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `searches` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `query_params` text COLLATE utf8_unicode_ci,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `user_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_searches_on_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `series` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ser_title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `clean_title` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `abbr_title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=126 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `textgroups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `urn` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `urn_end` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `group_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1877 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `tg_auth_works` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tg_id` int(11) DEFAULT NULL,
  `auth_id` int(11) DEFAULT NULL,
  `work_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `taw_tg_idx` (`tg_id`),
  KEY `taw_aid_idx` (`auth_id`),
  KEY `taw_wid_idx` (`work_id`),
  CONSTRAINT `taw_aid` FOREIGN KEY (`auth_id`) REFERENCES `authors` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `taw_tg` FOREIGN KEY (`tg_id`) REFERENCES `textgroups` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `taw_wid` FOREIGN KEY (`work_id`) REFERENCES `works` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=4116 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `encrypted_password` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `reset_password_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `reset_password_sent_at` datetime DEFAULT NULL,
  `remember_created_at` datetime DEFAULT NULL,
  `sign_in_count` int(11) DEFAULT '0',
  `current_sign_in_at` datetime DEFAULT NULL,
  `last_sign_in_at` datetime DEFAULT NULL,
  `current_sign_in_ip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_sign_in_ip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `guest` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_users_on_email` (`email`),
  UNIQUE KEY `index_users_on_reset_password_token` (`reset_password_token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `word_counts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `auth_id` int(11) NOT NULL,
  `total_words` int(11) DEFAULT NULL,
  `words_done` int(11) DEFAULT NULL,
  `tufts_google` int(11) DEFAULT NULL,
  `harvard_mellon` int(11) DEFAULT NULL,
  `to_do` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `wc_auth_idx` (`auth_id`),
  CONSTRAINT `wc_auth` FOREIGN KEY (`auth_id`) REFERENCES `authors` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `works` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `standard_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `textgroup_id` int(11) DEFAULT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `abbr_title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `language` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `word_count` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `w_tg_idx` (`textgroup_id`),
  CONSTRAINT `w_tg` FOREIGN KEY (`textgroup_id`) REFERENCES `textgroups` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=4127 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO schema_migrations (version) VALUES ('20130117165656');

INSERT INTO schema_migrations (version) VALUES ('20130117165657');

INSERT INTO schema_migrations (version) VALUES ('20130117165658');

INSERT INTO schema_migrations (version) VALUES ('20130117165659');

INSERT INTO schema_migrations (version) VALUES ('20130125181757');

INSERT INTO schema_migrations (version) VALUES ('20130125182026');

INSERT INTO schema_migrations (version) VALUES ('20130125182034');

INSERT INTO schema_migrations (version) VALUES ('20130125182048');

INSERT INTO schema_migrations (version) VALUES ('20130125182133');

INSERT INTO schema_migrations (version) VALUES ('20130326141323');

INSERT INTO schema_migrations (version) VALUES ('20130326141325');

INSERT INTO schema_migrations (version) VALUES ('20130328112701');

INSERT INTO schema_migrations (version) VALUES ('20130401181955');

INSERT INTO schema_migrations (version) VALUES ('20130503151406');

INSERT INTO schema_migrations (version) VALUES ('20130503151826');

INSERT INTO schema_migrations (version) VALUES ('20130503152142');

INSERT INTO schema_migrations (version) VALUES ('20130506152805');

INSERT INTO schema_migrations (version) VALUES ('20130506160519');

INSERT INTO schema_migrations (version) VALUES ('20130513191533');