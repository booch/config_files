exports.configuration = [
{
    type: 'popover',
    label: 'Go To',
    items: [
        {
            type: 'button',
            label: 'Definition',
            clickDispatchAction: 'symbol-view:go-to-declaration',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Line:',
            clickDispatchAction: 'go-to-line:toggle',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Top',
            clickDispatchAction: 'core:move-to-top',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Bottom',
            clickDispatchAction: 'core:move-to-bottom',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Spec',
            clickDispatchAction: 'rails-transporter:open-spec',
            dispatchActionTarget: 'editor'
        }
    ]
},
{
    type: 'popover',
    label: 'Change Case',
    items: [
        {
            type: 'button',
            label: 'Title',
            clickDispatchAction: 'change-case:title',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Sentence',
            clickDispatchAction: 'change-case:sentence',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Upper',
            clickDispatchAction: 'change-case:upper',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Lower',
            clickDispatchAction: 'change-case:lower',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Snake',
            clickDispatchAction: 'change-case:snake',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Camel',
            clickDispatchAction: 'change-case:camel',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Constant',
            clickDispatchAction: 'change-case:constant',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Kabob',
            clickDispatchAction: 'change-case:param',
            dispatchActionTarget: 'editor'
        }
    ]
}, {
    type: 'popover',
    label: 'Refactor',
    items: [
        {
            type: 'button',
            label: 'Reformat',
            clickDispatchAction: 'atom-beautify:beautify-editor',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Rename',
            clickDispatchAction: '???',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Extract Method',
            clickDispatchAction: 'ruby-on-rails-refactor:extract-method',
            dispatchActionTarget: 'editor'
        }
    ]
}, {
    type: 'popover',
    label: 'Copy',
    items: [
        {
            type: 'button',
            label: 'Relative Path',
            clickDispatchAction: 'copy-path:copy-project-relative-path',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Full Path',
            clickDispatchAction: 'editor:copy-path',
            dispatchActionTarget: 'editor'
        }
    ]
}, {
    type: 'popover',
    label: 'Insert',
    items: [
        {
            type: 'button',
            label: "Today's Date",
            clickDispatchAction: 'date:date',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Symbol',
            clickDispatchAction: '—',
            dispatchActionTarget: 'editor'
        }
    ]
}, {
    type: 'popover',
    label: 'Show',
    items: [
        {
            type: 'button',
            label: 'Preview',
            clickDispatchAction: '—',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Terminal',
            clickDispatchAction: 'platformio-ide-terminal:toggle', // Works!
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Git',
            clickDispatchAction: 'github:toggle-git-tab', // Works!
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'GitHub',
            clickDispatchAction: 'github:toggle-github-tab', // Works!
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Git Blame',
            clickDispatchAction: 'git-blame:toggle',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Git Diff',
            clickDispatchAction: 'git-diff:toggle-diff-list',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Markdown',
            clickDispatchAction: 'markdown-preview:toggle',
            dispatchActionTarget: 'editor'
        },
        {
            type: 'button',
            label: 'Tree',
            clickDispatchAction: 'tree-view:toggle',
            dispatchActionTarget: 'editor'
        }
    ]
}];
