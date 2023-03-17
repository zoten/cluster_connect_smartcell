import * as Vue from "https://cdn.jsdelivr.net/npm/vue@3.2.26/dist/vue.esm-browser.prod.js";

export function init(ctx, payload) {
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap"
  );

  const app = Vue.createApp({
    template: `
        <div class="app">
        <!-- Info Messages -->
        <div id="info-box" class="info-box">
          <p>Please note that every time this cell is evaluated, a new atom based on
          <span>secret's</span> value will be created. The same applies for <span>Module</span>
          and <span>Function</span> fields. Be sure to understand what it means for the BEAM VM! 🙏</p>
          <p>Please note also that arguments field is evaluated through <span>Code.eval_string/1</span>
          so please make sure you let connect to this livebook with trusted people only! 🙏</p>
        </div>

        <form @change="handleFieldChange">
          <div class="container">
            <div class="root">
              <BaseInput
                name="target_node"
                label="Node"
                type="text"
                placeholder="node@host"
                v-model="rootFields.target_node"
                class="input--md"
              />
              <BaseSelect
                name="target_node_bound"
                label="Node (bound)"
                :layer="index"
                v-model="rootFields.target_node_bound"
                :options="nodeBounds"
                :disabled="!nodeBoundsExist"
              />
              <BaseInput
                name="erlang_cookie"
                label="Cookie"
                type="text"
                placeholder="secret"
                v-model="rootFields.erlang_cookie"
                class="input--md"
              />
              <BaseSelect
                name="erlang_cookie_bound"
                label="Cookie (bound)"
                :layer="index"
                v-model="rootFields.erlang_cookie_bound"
                :options="cookieBounds"
                :disabled="!cookieBoundsExist"
              />
            </div>

            <div class="layers">
              <div class="row">
                <p class="current-values">Target Node <span class="current-value">{{targetNode}}</span> Cookie <span class="current-value">{{targetCookie}}</span></p>
              </div>
            </div>

            <div class="layers">
              <div class="row">
                <CommonInput
                  name="module"
                  label="Module"
                  type="text"
                  placeholder="MyModule"
                  :layer="index"
                  v-model="rootFields.module"
                  class="input--md"
                  :required
                />

                <CommonInput
                  name="function"
                  label="Function"
                  type="text"
                  :layer="index"
                  placeholder=":my_function"
                  v-model="rootFields.function"
                  class="input--md"
                  :required
                />
                <div class="field"></div>
              </div>

              <div class="row">
                <CommonInput
                  name="arguments"
                  label="Arguments"
                  type="text"
                  :layer="index"
                  placeholder="[1, 2, 3]"
                  v-model="rootFields.arguments"
                  class="input--lg"
                  :required
                />
              </div>

              <div class="row">
                <CommonInput
                  name="bind_result"
                  label="Bind Result to"
                  type="text"
                  :layer="index"
                  placeholder="varname"
                  v-model="rootFields.bind_result"
                  class="input--lg"
                />
              </div>
            </div>

            <div class="layers">
              <div class="row">
                <p class="current-values">Command <span class="current-value">{{ command }}</span></p>
              </div>
            </div>
          </div>
        </form>
        </div>
      `,
    data() {
      return {
        rootFields: payload.root_fields,
        nodeBounds: payload.node_bounds,
        cookieBounds: payload.cookie_bounds,
      }
    },

    computed: {
      nodeBoundsExist() {
        return (Object.keys(this.nodeBounds).length > 0)
      },
      cookieBoundsExist() {
        return (Object.keys(this.cookieBounds).length > 0)
      },
      targetNode() {
        if (this.rootFields.target_node_bound.length > 0) return this.rootFields.target_node_bound;
        if (this.rootFields.target_node.length > 0) return this.rootFields.target_node;
        return "N/A"
      },
      targetCookie() {
        if (this.rootFields.erlang_cookie_bound.length > 0) return this.rootFields.erlang_cookie_bound;
        if (this.rootFields.erlang_cookie.length > 0) return this.rootFields.erlang_cookie;
        return "N/A"
      },
      command() {
        if (!(this.targetNode && this.rootFields.module && this.rootFields.function && this.rootFields.arguments)) return "N/A";

        let result_part = (this.rootFields.bind_result) ? (this.rootFields.bind_result + " = ") : "";

        return result_part +
          ":erpc.call(:\"" +
          this.targetNode +
          "\", " +
          this.rootFields.module +
          ", :\"" +
          this.rootFields.function +
          "\", " +
          this.rootFields.arguments +
          ")";
      }
    },

    methods: {
      handleFieldChange(event) {
        const { name, value } = event.target;
        ctx.pushEvent("update_field", { field: name, value });
      },
    },

    components: {
      BaseSelect: {
        props: {
          label: {
            type: String,
            default: "",
          },
          modelValue: {
            type: [String, Number],
            default: "",
          },
          options: {
            type: Array,
            default: {},
            required: true,
          },
          required: {
            type: Boolean,
            default: false,
          },
          selectClass: {
            type: String,
            default: "",
          },
          fieldClass: {
            type: String,
            default: "field",
          },
        },
        methods: {},
        template: `
            <div class="root-field">
              <label class="input-label">{{ label }}</label>
              <select
                :value="modelValue"
                v-bind="$attrs"
                @change="$emit('update:modelValue', $event.target.value)"
                class="input"
                :class="[selectClass]"
              >
                <option v-if="!required" value="">--</option>
                <option
                  v-for="(value, key) in options"
                  :value="value"
                  :key="key"
                  :selected="value === modelValue"
                >{{ key }} ({{ value }})</option>
              </select>
            </div>
          `,
      },
      BaseInput: {
        props: {
          label: {
            type: String,
            default: "",
          },
          modelValue: {
            type: [String, Number],
            default: "",
          },
        },
        template: `
          <div class="root-field">
            <label class="input-label">{{ label }}</label>
            <input
              :value="modelValue"
              @input="$emit('update:modelValue', $event.target.value)"
              v-bind="$attrs"
              class="input"
            >
          </div>
        `,
      },
      CommonInput: {
        props: {
          label: {
            type: String,
            default: "",
          },
          modelValue: {
            type: [String, Number],
            default: "",
          },
        },
        template: `
          <div class="field">
            <label class="input-label">{{ label }}</label>
            <input
              :value="modelValue"
              @input="$emit('update:modelValue', $event.target.value)"
              v-bind="$attrs"
              class="input"
            >
          </div>
        `,
      },
    }
  }).mount(ctx.root);

  ctx.handleEvent("update_root", ({ fields }) => {
    setRootValues(fields);
  });

  ctx.handleEvent("update_binding", ({ bindings }) => {
    setBindings(bindings);
  });

  ctx.handleSync(() => {
    // Synchronously invokes change listeners
    document.activeElement &&
      document.activeElement.dispatchEvent(
        new Event("change", { bubbles: true })
      );
  });

  function setRootValues(fields) {
    for (const field in fields) {
      app.rootFields[field] = fields[field];
    }
  }

  function setBindings(bindings) {
    app.nodeBounds = bindings.possible_nodes;
    app.cookieBounds = bindings.possible_secrets;
  }
};
