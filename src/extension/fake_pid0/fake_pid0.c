/* -*- c-set-style: "K&R"; c-basic-offset: 8 -*-
 *
 * This file is part of PRoot.
 *
 * Copyright (C) 2015 STMicroelectronics
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA.
 */

#include <stdint.h>      /* intptr_t, */
#include <stdbool.h>     /* bool, true, false */
#include <sys/types.h>   /* pid_t, */

#include "extension/extension.h"
#include "syscall/syscall.h"
#include "syscall/sysnum.h"
#include "syscall/seccomp.h"
#include "tracee/tracee.h"
#include "tracee/reg.h"

/* List of syscalls handled by this extension.  */
static FilteredSysnum filtered_sysnums[] = {
	{ PR_getpid,	FILTER_SYSEXIT },
	FILTERED_SYSNUM_END,
};

/**
 * Handler for this @extension.  It is triggered each time an @event
 * occurred.  See ExtensionEvent for the meaning of @data1 and @data2.
 */
int fake_pid0_callback(Extension *extension, ExtensionEvent event, intptr_t data1, intptr_t data2)
{
	(void) data1;
	(void) data2;

	switch (event) {
	case INITIALIZATION:
		extension->filtered_sysnums = filtered_sysnums;
		return 0;

	case INHERIT_PARENT:
		/* This extension is inheritable.  */
		return 1;

	case INHERIT_CHILD: {
		/* Nothing special to do.  */
		return 0;
	}

	case SYSCALL_EXIT_END: {
		Tracee *tracee = TRACEE(extension);
		word_t sysnum;

		sysnum = get_sysnum(tracee, ORIGINAL);
		
		/* Only handle getpid syscall */
		if (sysnum != PR_getpid)
			return 0;

		/* Return PID 1 for the first contained process */
		poke_reg(tracee, SYSARG_RESULT, 1);
		return 0;
	}

	default:
		return 0;
	}
}
